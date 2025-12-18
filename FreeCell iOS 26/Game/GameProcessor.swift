import Foundation
import os.log

final class GameProcessor: Processor {
    weak var coordinator: (any RootCoordinatorType)?

    weak var presenter: (any ReceiverPresenter<GameEffect, GameState>)?

    lazy var stopwatch: any StopwatchType = Stopwatch(delegate: self)

    lazy var animator: any AnimatorType = Animator(processor: self)

    var state = GameState()

    /// This method effectively subscribes to the publishable property in the observable
    /// Lifetime instance. Once called, it sets up a Task that loops forever. The `dropFirst` is
    /// because we get a `.becomeActive` message when subscribing in the first place, which we ignore.
    func listenForEvent() async throws {
        for await event in services.lifetime.stream.dropFirst() {
            try Task.checkCancellation()
            switch event {
            case .becomeActive:
                logger.log("become active")
                await stopwatch.resumeIfPaused()
            case .enterBackground:
                logger.log("enter background")
                await presenter?.receive(.removeConfetti)
                services.persistence.saveGame(
                    SavedGame(
                        layout: state.layout,
                        undoStack: state.undoStack,
                        redoStack: state.redoStack,
                        timeTaken: stopwatch.elapsedTime
                    )
                )
            case .resignActive:
                logger.log("resign active")
                await stopwatch.pause()
            }
        }
    }

    /// Variable that gives us a handle on our perpetually looping task, so that we can
    /// cancel it. We do not in fact intend to cancel it; it really does just loop forever.
    /// However, it's nice to have a way out, e.g. when testing, plus the population of this
    /// variable tells us that our subscription is in place, also useful when testing.
    var listenForEventTask: Task<(), any Error>?

    func receive(_ action: GameAction) async {
        switch action {
        case .autoplay:
            await ensureNeutralState()
            await autoplay()
            await checkGameEndAndStopwatch(action: action)
        case .deal:
            // if game in progress, must lose it in order to proceed; tell the user
            if state.gameProgress != .gameOver {
                let result = await coordinator?.showAlert(
                    title: "Really Deal?",
                    message: """
                    You have not yet finished the current game. \
                    Do you really want to lose this game and deal another game?
                    """,
                    buttonTitles: ["Cancel", "Deal"]
                )
                if result == "Cancel" {
                    return
                }
                saveGame(won: false)
            }
            // deal, ensuring this is not a duplicate of an existing deal
            do {
                let stats = await services.stats.stats
                var deck: any DeckType = services.deckFactory.makeDeck()
                repeat {
                    deck.shuffle()
                    state.layout.deal(deck)
                } while stats[state.layout.tableauDescription] != nil
            }
            // start game ex nihilo; `Layout()` tells the animator that this is a new deal
            await beginGame(from: 0, oldLayout: Layout())
        case .didInitialLayout:
            // called exactly once early in the lifetime of the app
            // set up our listener tasks
            listenForEventTask = Task {
                try await listenForEvent()
            }
            // set prefs properties in state
            for pref in Pref.list {
                let pref = services.persistence.loadPref(pref)
                state[pref.key] = pref.value
            }
            state.animationSpeed = services.persistence.loadAnimationSpeed()
            // restore game if there was one; this is a fully restorable game so cannot call `beginGame`
            if let game = services.persistence.loadGame() {
                state.layout = game.layout
                state.undoStack = game.undoStack
                state.redoStack = game.redoStack
                if state.gameIsOver {
                    state.gameProgress = .gameOver
                } else {
                    state.gameProgress = .dealtWaitingForFirstMove
                }
                await stopwatch.reset(to: game.timeTaken)
                // the stopwatch is now _stopped_ at the loaded time
            } else {
                await stopwatch.reset(to: 0)
            }
            await ensureNeutralState() // initial state presentation
            await services.stats.loadStats() // actor, interface not blocked
            logger.log("stats loaded")
        case .hint:
            state.firstTapLocation = nil
            state.enablements = hintEnablements()
            await presenter?.present(state)
            await checkStopwatch()
        case .longPress(let location, let internalIndex):
            await ensureNeutralState()
            let card = state.layout.card(at: location, internalIndex: internalIndex)
            let allCards = state.layout.allLocationsAndCards()
            let allCardsFiltered = allCards.filter { $0.card.rank == card?.rank }
            await presenter?.receive(.tint(allCardsFiltered))
            // no stopwatch check, it's distracting, and so what if it is first move?
        case .longPressEnded:
            await presenter?.receive(.tintsOff)
            await checkStopwatch()
        case .redo:
            if state.redoStack.count > 0 {
                let oldLayout = state.layout
                state.undoStack.append(state.layout)
                state.layout = state.redoStack.removeLast()
                await ensureNeutralState()
                await animator.animate(oldLayout: oldLayout, newLayout: state.layout, speed: state.animationSpeed)
            }
            await checkStopwatch()
        case .redoAll:
            if state.redoStack.count > 0 {
                let oldLayout = state.layout
                state.undoStack.append(state.layout)
                while !state.redoStack.isEmpty {
                    state.undoStack.append(state.redoStack.removeLast())
                }
                state.layout = state.undoStack.removeLast()
                await ensureNeutralState()
                await animator.animate(oldLayout: oldLayout, newLayout: state.layout, speed: state.animationSpeed)
            }
            await checkStopwatch()
        case .resized:
            await ensureNeutralState()
        case .showHelp:
            await stopwatch.pause()
            coordinator?.showHelp(.help)
        case .showImportExport:
            await stopwatch.pause()
            coordinator?.showImportExport()
        case .showMicrosoft(let wrapper):
            await stopwatch.pause()
            coordinator?.showMicrosoft(wrapper)
        case .showPrefs:
            await stopwatch.pause()
            // gather up prefs from state _in order_
            var prefs = [Pref]()
            for key in PrefKey.allCases {
                prefs.append(Pref(key: key, value: state[key]))
            }
            // send prefs together with speed to Prefs module via coordinator
            coordinator?.showPrefs(PrefsState(prefs: prefs, speed: state.animationSpeed))
        case .showRules:
            await stopwatch.pause()
            coordinator?.showHelp(.rules)
        case .showStats:
            await stopwatch.pause()
            coordinator?.showStats()
        case .tapBackground:
            // user can always tap the background to get out of any "mode"
            await ensureNeutralState()
            await checkStopwatch()
        case .tapped(let tap):
            if state.gameIsOver == true && state.gameProgress == .gameOver {
                // edge case; `.tapped` comes from _card view_ so view controller never hears about it
                // therefore _we_ have to _tell_ the view controller to remove the confetti if any
                await presenter?.receive(.removeConfetti)
            }
            if state.firstTapLocation == nil {
                await handleFirstTap(tap)
            } else {
                await handleSecondTap(tap)
            }
            await checkGameEndAndStopwatch(action: action)
        case .undo:
            if state.undoStack.count > 0 {
                let oldLayout = state.layout
                state.redoStack.append(state.layout)
                state.layout = state.undoStack.removeLast()
                await ensureNeutralState()
                await animator.animate(oldLayout: oldLayout, newLayout: state.layout, speed: state.animationSpeed)
            }
            await checkStopwatch()
        case .undoAll:
            if state.undoStack.count > 0 {
                let oldLayout = state.layout
                state.redoStack.append(state.layout)
                while !state.undoStack.isEmpty {
                    state.redoStack.append(state.undoStack.removeLast())
                }
                state.layout = state.redoStack.removeLast()
                await ensureNeutralState()
                await animator.animate(oldLayout: oldLayout, newLayout: state.layout, speed: state.animationSpeed)
            }
            await checkStopwatch()
        }
    }
    
    /// Animate layout and prepare for the user to make the first move. This could be because the
    /// user said "deal" (new game) or because the user asked to replay a previous lost game (in which
    /// case we start fresh at the opening layout but with time already on the clock).
    /// - Parameters:
    ///   - time: The elapsed time to which to reset the stopwatch.
    ///   - oldLayout: The old layout preceding the current layout, so we can animate the
    ///   former to the latter; `Layout()` means as if dealing from an offscreen deck.
    func beginGame(from time: TimeInterval, oldLayout: Layout) async {
        state.undoStack = []
        state.redoStack = []
        state.layout.moveCode = nil
        state.gameProgress = .dealtWaitingForFirstMove
        await ensureNeutralState()
        await animator.animate(oldLayout: oldLayout, newLayout: state.layout, speed: state.animationSpeed)
        await stopwatch.reset(to: time)
    }

    /// This is something we do pretty often. The "neutral" state is that the game is completely
    /// paused, waiting for the user to make a move. No first tap is registered and no card views
    /// are highlighted.
    func ensureNeutralState() async {
        state.firstTapLocation = nil
        state.enablements = state.baseEnablements
        await presenter?.present(state)
    }
    
    /// If you can make a safe move from the given location to the foundations, make it and
    /// return true; otherwise, return false.
    /// - Parameter location: The location from which to try to move safely to a foundation.
    /// - Returns: Whether the move was safe and possible. If we return `true`, the move has
    /// been made — the layout has been altered. If we return `false`, nothing has happened at all.
    func playToFoundationIfSafeAndPossible(location: Location) -> Bool {
        if let card = state.layout.card(at: location) {
            if card.canGoOn(state.layout.foundations) {
                if !state.layout.mightNeed(card: card) {
                    let card = state.layout.surrenderCard(from: location)
                    state.layout.foundations.accept(card: card)
                    return true
                }
            }
        }
        return false
    }

    /// Do a complete round of autoplay to foundations, i.e. make every possible safe move to
    /// the foundations. This call should be made only from a neutral state, and it constitutes
    /// a complete self-contained move in and of itself, returning to a neutral state afterwards.
    ///
    /// Observe that we do _not_ check the `state.autoplay` preference setting. This is deliberate!
    /// The user can _force_ us to autoplay (using double tap on the background). Therefore it is
    /// the job _of the caller_ to check `state.autoplay` before making this call, if needed.
    func autoplay() async {
        let oldLayout = state.layout
        var moved = false
        let locations: [Location] = (
            (0..<8).map { Location(category: .column, index: $0) } +
            (0..<4).map { Location(category: .freeCell, index: $0) }
        )
        repeat {
            moved = false
            for location in locations {
                if playToFoundationIfSafeAndPossible(location: location) {
                    moved = true
                }
            }
        } while moved
        if state.layout != oldLayout {
            state.undoStack.append(oldLayout)
            state.redoStack = []
            state.layout.moveCode = nil // user didn't do anything to get here
            await ensureNeutralState()
            await animator.animate(oldLayout: oldLayout, newLayout: state.layout, speed: state.animationSpeed)
        }
    }
    
    /// The user has tapped a card view when there is no recorded first tap. Therefore _this_ is
    /// the first tap. Respond appropriately.
    /// - Parameter location: The location of the card view the user tapped.
    func handleFirstTap(_ location: Location) async {
        // Bad taps, return to neutral and stop.
        guard state.layout.card(at: location) != nil, location.category != .foundation else {
            await ensureNeutralState() // hints might be showing
            return
        }

        // Tap on a safe autoplayable: just play it! This is a complete move of itself, so we
        // respond just like the completion of a second tap.
        let oldLayout = state.layout
        if playToFoundationIfSafeAndPossible(location: location) { // TODO: check a pref here?
            state.undoStack.append(oldLayout)
            state.redoStack = []
            state.layout.moveCode = nil // counts as an autoplay
            await ensureNeutralState()
            await animator.animate(oldLayout: oldLayout, newLayout: state.layout, speed: state.animationSpeed)
            if state[.automoveToFoundations] {
                await autoplay()
            }
            return
        }

        // Only one move is even possible, and the "unambiguous" pref is on; make the move!
        if state[.automoveOnFirstTap] {
            if let _ = try? await unambiguousMove(location: location) {
                return // We have made the move _completely_, including neutrality and autoplay.
            }
        }

        // The most usual response: this is a first tap and we must wait for the second tap, so
        // we store the tap and perform all highlighting / enabling as appropriate. Thus we
        // _must_ do a presentation, to give the presenter a chance to adjust the interface.
        state.firstTapLocation = location
        state.enablements = if state[.highlightDestinations] {
            firstTapEnablements(for: location)
        } else {
            state.baseEnablements
        }
        await presenter?.present(state)
    }
    
    /// Given the location of the first tap, construct and return a dictionary where the keys are
    /// _all_ the locations of the layout and whose values state whether each location should be
    /// "lit up" (to indicate that one can play from the first tap location to here) or not
    /// (to indicate that one cannot).
    /// - Parameter location: The location of the first tap.
    /// - Returns: The dictionary of locations and enablements.
    func firstTapEnablements(for location: Location) -> [Location: GameState.Enablement] {
        guard let card = state.layout.card(at: location) else {
            return state.baseEnablements
        }
        // begin by _assuming_ that all slots are disabled
        var result = state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
        // now enable those that should be enabled
        switch location.category {
        case .foundation:
            fatalError("this cannot happen")
        case .freeCell:
            if card.canGoOn(state.layout.foundations) { // if can go on _any_ foundation, illuminate _all_
                (0..<4).forEach {
                    result[Location(category: .foundation, index: $0)] = .enabled
                }
            }
            (0..<8).forEach { // if can go on a column, illuminate that one
                if card.canGoOn(state.layout.columns[$0]) {
                    result[Location(category: .column, index: $0)] = .enabled
                }
            }
        case .column:
            if state.layout.numberOfEmptyFreeCells > 0 { // if can go on _any_ freecell, illuminate _all_
                (0..<4).forEach {
                    result[Location(category: .freeCell, index: $0)] = .enabled
                }
            }
            if card.canGoOn(state.layout.foundations) { // if can go on _any_ foundation, illuminate _all_
                (0..<4).forEach {
                    result[Location(category: .foundation, index: $0)] = .enabled
                }
            }
            (0..<8).forEach { // if can be moved to a column, illuminate that one
                if state.layout.howManyCardsCanMoveLegally(
                    from: location.index,
                    to: $0,
                    sequenceMoves: state[.sequenceMoves],
                    supermoves: state[.supermoves]
                ) > 0 {
                    result[Location(category: .column, index: $0)] = .enabled
                }
            }
        }
        return result
    }
    
    /// The user has asked for a hint: what locations can be the source of a legal move? Construct
    /// and return a dictionary of _all_ the locations of the layout, where the enablement answers
    /// the question, yes or no, whether each location can be the source of a legal move.
    /// - Returns: The dictionary of locations and enablements.
    func hintEnablements() -> [Location: GameState.Enablement] {
        var result = state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
        // enable all free cells and columns that can go on a _nonempty_ foundation or column
    freecells:
        for source in (0..<4) {
        thisFreeCell:
            if let card = state.layout.freeCells[source].card {
                if card.canGoOn(state.layout.foundations) {
                    result[Location(category: .freeCell, index: source)] = .enabled
                    continue freecells
                }
                for dest in (0..<8) {
                    if card.canGoOn(state.layout.columns[dest]) && !state.layout.columns[dest].isEmpty {
                        result[Location(category: .freeCell, index: source)] = .enabled
                        continue freecells
                    }
                }
            }
        }
    columns:
        for source in (0..<8) {
            if let card = state.layout.columns[source].card {
                if card.canGoOn(state.layout.foundations) {
                    result[Location(category: .column, index: source)] = .enabled
                    continue columns
                }
            }
            for dest in (0..<8) {
                if dest != source && !state.layout.columns[dest].isEmpty {
                    if state.layout.howManyCardsCanMoveLegally(
                        from: source,
                        to: dest,
                        sequenceMoves: state[.sequenceMoves],
                        supermoves: state[.supermoves]
                    ) > 0 {
                        result[Location(category: .column, index: source)] = .enabled
                        continue columns
                    }
                }
            }
        }
        return result
    }
    
    /// Given a source location, look for the possible move destination locations. If there is
    /// _exactly one_ possible move, _make it_ — and if not, throw.
    /// - Parameter location: The source location.
    /// - Throws: If there are _no_ possible move destinations, or if there are _multiple_
    /// possible move destinations. If we throw, we did not move; if we _don't_ throw, we _did_ move.
    ///
    /// If we make a move, it is a _complete_ move, exactly as if the user had tapped the source
    /// and then the one possible destination. We are back in the neutral state.
    func unambiguousMove(location: Location) async throws {
        var destination: Location?
        // gateway so that an attempt to set an already set `destination` will throw;
        // call `oncer.doYourThing()`, and _never_ set `destination` directly
        var oncer = Oncer {
            destination = $0
        }
        // utility I'm going to need later on; edge case where `destination` and some other
        // prospective location are both empty columns
        func emptyColumns(_ location1: Location?, _ location2: Location?) -> Bool {
            if let location1, let location2 {
                if state.layout.card(at: location1) == nil {
                    if state.layout.card(at: location2) == nil {
                        if location1.category == .column {
                            if location2.category == .column {
                                return true
                            }
                        }
                    }
                }
            }
            return false
        }
        // okay, here we go
        switch location.category {
        case .foundation:
            fatalError("this cannot happen")
        case .freeCell:
            if let card = state.layout.card(at: location) {
                if card.canGoOn(state.layout.foundations) {
                    try oncer.doYourThing(
                        Location(
                            category: .foundation,
                            index: state.layout.indexOfFoundation(for: card.suit)
                        )
                    )
                }
                for index in 0..<8 {
                    if card.canGoOn(state.layout.columns[index]) {
                        if emptyColumns(destination, Location(category: .column, index: index)) {
                            continue
                        }
                        try oncer.doYourThing(
                            Location(
                                category: .column,
                                index: index
                            )
                        )
                    }
                }
            }
        case .column:
            if let card = state.layout.card(at: location) {
                if card.canGoOn(state.layout.foundations) {
                    try oncer.doYourThing(
                        Location(
                            category: .foundation,
                            index: state.layout.indexOfFoundation(for: card.suit)
                        )
                    )
                }
                if let index = state.layout.indexOfFirstEmptyFreeCell {
                    try oncer.doYourThing(
                        Location(
                            category: .freeCell,
                            index: index
                        )
                    )
                }
                for index in (0..<8) {
                    if index != location.index && state.layout.howManyCardsCanMoveLegally(
                        from: location.index,
                        to: index,
                        sequenceMoves: state[.sequenceMoves],
                        supermoves: state[.supermoves]
                    ) > 0 {
                        if emptyColumns(destination, Location(category: .column, index: index)) {
                            continue
                        }
                        try oncer.doYourThing(
                            Location(
                                category: .column,
                                index: index
                            )
                        )
                    }
                }
            }
        }
        guard let destination else {
            throw OnceError.notEnough // we didn't find _any_ moves!
        }
        // We found exactly one move, so make it — by pretending that `location` was the first tap
        // and `destination` is the second!
        state.firstTapLocation = location
        await handleSecondTap(destination)
    }
    
    /// The user has tapped when there was a stored first tap location. Therefore this is the
    /// _second_ tap location. So if possible move from the first location to the second and
    /// return to a neutral state, followed by a round of autoplay.
    /// - Parameter secondTapLocation: The second tap location (the first tap location is stored
    /// in the `state` as the `firstTapLocation`).
    func handleSecondTap(_ secondTapLocation: Location) async {
        guard let firstTapLocation = state.firstTapLocation else {
            return // shouldn't happen
        }
        guard let card = state.layout.card(at: firstTapLocation) else {
            return // shouldn't happen
        }
        let oldLayout = state.layout
        var moveCodeSecondCharacter = ""
        switch secondTapLocation.category {
        case .foundation:
            // doesn't matter which foundation was tapped; if it can move, move it
            if card.canGoOn(state.layout.foundations) {
                let card = state.layout.surrenderCard(from: firstTapLocation)
                state.layout.foundations.accept(card: card)
                moveCodeSecondCharacter = "h"
            }
        case .freeCell:
            // doesn't matter which free cell was tapped; if it can move, move to first empty
            guard firstTapLocation.category == .column else {
                break // only a column can be moved to a free cell
            }
            guard let targetIndex = state.layout.indexOfFirstEmptyFreeCell else {
                break // we need a free cell to move to
            }
            let card = state.layout.surrenderCard(from: firstTapLocation)
            state.layout.freeCells[targetIndex].accept(card: card)
            moveCodeSecondCharacter = Location(category: .freeCell, index: targetIndex).standardNotation
        case .column:
            switch firstTapLocation.category {
            case .foundation: break // shouldn't happen
            case .freeCell:
                if card.canGoOn(state.layout.columns[secondTapLocation.index]) {
                    let card = state.layout.surrenderCard(from: firstTapLocation)
                    state.layout.columns[secondTapLocation.index].accept(card: card)
                    moveCodeSecondCharacter = Location(category: .column, index: secondTapLocation.index).standardNotation
                }
            case .column:
                let number = state.layout.howManyCardsCanMoveLegally(
                    from: firstTapLocation.index,
                    to: secondTapLocation.index,
                    sequenceMoves: state[.sequenceMoves],
                    supermoves: state[.supermoves]
                )
                if number > 0 {
                    state.layout.columns[firstTapLocation.index].cards.suffix(number).forEach {
                        state.layout.columns[secondTapLocation.index].accept(card: $0)
                    }
                    state.layout.columns[firstTapLocation.index].cards.removeLast(number)
                    moveCodeSecondCharacter = Location(category: .column, index: secondTapLocation.index).standardNotation
                }
            }
        }
        if state.layout != oldLayout {
            state.undoStack.append(oldLayout)
            state.redoStack = []
            state.layout.moveCode = firstTapLocation.standardNotation + moveCodeSecondCharacter
            await ensureNeutralState()
            await animator.animate(oldLayout: oldLayout, newLayout: state.layout, speed: state.animationSpeed)
        } else {
            await ensureNeutralState() // bad second tap! restore neutrality, wait for another tap-tap
        }
        if state[.automoveToFoundations] {
            await autoplay()
        }
    }

    /// Check to see whether the game is over. If it is, set the stopwatch and game progress
    /// appropriately, and show the confetti and save the game. If this method is called, it
    /// must be called _before_ `checkTheStopwatch`, because the latter depends upon changes
    /// we may make here. Therefore _we_ call it here. Do not call _both_ `checkGame` and
    /// `checkStopwatch`.
    func checkGameEndAndStopwatch(action: GameAction) async {
        // these are the only actions for which "win the game" makes sense; we should not have
        // to check this (i.e. `receive` should call only from the correct actions) but this is
        // an extra safety check
        switch action {
        case .autoplay, .tapped:
            if state.gameIsOver {
                await stopwatch.stop()
                if state.gameProgress == .inProgress {
                    state.gameProgress = .gameOver
                    saveGame(won: true)
                    Task {
                        await presenter?.receive(.confetti)
                    }
                }
            }
        default: break
        }
        await checkStopwatch()
    }

    /// Based on the game progress and the state of the stopwatch, set the game progress and
    /// and the stopwatch. Must be called only _after_ `checkGameEnd`, which therefore calls it.
    func checkStopwatch() async {
        if state.gameProgress == .gameOver {
            return
        }
        state.gameProgress = .inProgress
        switch stopwatch.state {
        case .paused:
            await stopwatch.resumeIfPaused()
        case .running:
            await stopwatch.advance()
        case .stopped:
            await stopwatch.start()
        }
    }

    /// Save the game into the stats.
    /// - Parameter won: Whether the game was won or lost.
    func saveGame(won: Bool) {
        let codes = (state.undoStack + [state.layout]).compactMap { $0.moveCode }
        let stat = Stat(
            dateFinished: (services.dateType.init() as? Date) ?? Date.distantPast,
            won: won,
            // if user ever moved and never undid all the way, the initial layout is sitting
            // at the start of the undo stack; but otherwise it is the _current_ layout
            initialLayout: state.undoStack.first ?? state.layout,
            movesCount: codes.count,
            timeTaken: stopwatch.elapsedTime,
            codes: codes
        )
        Task { // because the actual saving may be time consuming
            do {
                try await services.stats.saveStat(stat)
            } catch {
                print(error) // TODO: Do something real here?
            }
        }
    }
    
    /// Interrupt the current game, saving it as lost if it hasn't been won, and deal a new game
    /// using the given initial layout and time taken.
    /// - Parameters:
    ///   - initialLayout: The layout for the initial deal of the new game.
    ///   - timeTaken: Elapsed time to put on the stopwatch.
    func replaceGame(initialLayout: Layout, timeTaken: TimeInterval) async {
        var oldLayout = Layout() // by default, deal as if from a deck
        if state.gameProgress != .gameOver { // if there is a current game...
            saveGame(won: false) // ... save it
            oldLayout = state.layout // instead of deck deal, rearrange existing cards
        }
        state.layout = initialLayout
        await beginGame(from: timeTaken, oldLayout: oldLayout)
    }
}

extension GameProcessor: StopwatchDelegate {
    func stopwatchDidUpdate(_ timeInterval: TimeInterval) async {
        await presenter?.receive(.updateStopwatch(timeInterval))
    }
}

extension GameProcessor: StatsDelegate {
    func resume(initialLayout: Layout, timeTaken: TimeInterval) async {
        await replaceGame(initialLayout: initialLayout, timeTaken: timeTaken)
    }
}

extension GameProcessor: ExportDelegate {
    func exportCurrentGame() {
        // info we need to gather is exactly like `saveGame`
        let codes = (state.undoStack + [state.layout]).compactMap { $0.moveCode }
        let initialLayout = state.undoStack.first ?? state.layout
        let message = services.exporter.messageText(layout: initialLayout, moves: codes)
        coordinator?.showMail(message: message)
    }

    func importGame(_ text: String?) async {
        guard let text else { return }
        guard let newLayout = Layout(shlomiTableauDescription: text) else { return }
        await replaceGame(initialLayout: newLayout, timeTaken: 0)
    }
}

extension GameProcessor: MicrosoftDelegate {
    func dealMicrosoftNumber(_ dealNumber: Int) async {
        var newLayout = Layout()
        newLayout.deal(microsoftDealNumber: dealNumber)
        await replaceGame(initialLayout: newLayout, timeTaken: 0)
    }
}

extension GameProcessor: PrefsDelegate {
    func prefChanged(_ prefKey: PrefKey, value: Bool) async {
        state[prefKey] = value
        await presenter?.present(state)
        services.persistence.savePref(Pref(key: prefKey, value: value))
    }

    func speedChanged(index: Int) async {
        let speed = GameState.AnimationSpeed.allCases[index]
        state.animationSpeed = speed
        services.persistence.saveAnimationSpeed(speed)
    }
}
