import Foundation

final class GameProcessor: Processor {
    weak var coordinator: (any RootCoordinatorType)?

    weak var presenter: (any ReceiverPresenter<GameEffect, GameState>)?

    lazy var stopwatch: StopwatchType = Stopwatch(delegate: self)

    var state = GameState()

    func receive(_ action: GameAction) async {
        switch action {
        case .autoplay:
            await autoplay()
            await checkTheStopwatch()
        case .deal:
            var deck = Deck()
            deck.shuffle()
            state.layout.deal(deck)
            state.undoStack = []
            state.redoStack = []
            state.gameInProgress = true
            await ensureNeutralState()
            await stopwatch.reset()
        case .hint:
            state.firstTapLocation = nil
            state.enablements = hintEnablements()
            await presenter?.present(state)
            await checkTheStopwatch()
        case .longPress(let location, let internalIndex):
            await ensureNeutralState() // TODO: okay?
            let card = state.layout.card(at: location, internalIndex: internalIndex)
            let allCards = state.layout.allLocationsAndCards()
            let allCardsFiltered = allCards.filter { $0.card.rank == card?.rank }
            await presenter?.receive(.tint(allCardsFiltered))
            // no stopwatch check, it's distracting, and so what if it is first move?
        case .longPressEnded:
            await presenter?.receive(.tintsOff)
            await checkTheStopwatch()
        case .redo:
            if state.redoStack.count > 0 {
                state.undoStack.append(state.layout)
                state.layout = state.redoStack.removeLast()
                await ensureNeutralState()
            }
            await checkTheStopwatch()
        case .redoAll:
            if state.redoStack.count > 0 {
                state.undoStack.append(state.layout)
                while !state.redoStack.isEmpty {
                    state.undoStack.append(state.redoStack.removeLast())
                }
                state.layout = state.undoStack.removeLast()
                await ensureNeutralState()
            }
            await checkTheStopwatch()
        case .tapBackground:
            // user can always tap the background to get out of any "mode"
            await ensureNeutralState()
            await checkTheStopwatch()
        case .tapped(let tap):
            if state.gameIsOver == true && state.gameInProgress == false {
                // edge case; `.tapped` comes from _card view_ so view controller never hears about it
                // therefore _we_ have to _tell_ the view controller to remove the confetti if any
                await presenter?.receive(.removeConfetti)
            }
            if state.firstTapLocation == nil {
                await handleFirstTap(tap)
            } else {
                await handleSecondTap(tap)
            }
            await checkTheStopwatch()
        case .undo:
            if state.undoStack.count > 0 {
                state.redoStack.append(state.layout)
                state.layout = state.undoStack.removeLast()
                await ensureNeutralState()
            }
            await checkTheStopwatch()
        case .undoAll:
            if state.undoStack.count > 0 {
                state.redoStack.append(state.layout)
                while !state.undoStack.isEmpty {
                    state.redoStack.append(state.undoStack.removeLast())
                }
                state.layout = state.redoStack.removeLast()
                await ensureNeutralState()
            }
            await checkTheStopwatch()
        }
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
        }
        await ensureNeutralState()
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
            await ensureNeutralState()
            if state.autoplay {
                await autoplay()
            }
            return
        }

        // Only one move is even possible, and the "unambiguous" pref is on; make the move!
        if state.unambiguousMove {
            if let _ = try? await unambiguousMove(location: location) {
                return // We have made the move _completely_, including neutrality and autoplay.
            }
        }

        // The most usual response: this is a first tap and we must wait for the second tap, so
        // we store the tap and perform all highlighting / enabling as appropriate. Thus we
        // _must_ do a presentation, to give the presenter a chance to adjust the interface.
        state.firstTapLocation = location
        state.enablements = if state.showDestinations {
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
                    sequenceMoves: state.sequenceMoves,
                    supermoves: state.supermoves
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
                        sequenceMoves: state.sequenceMoves,
                        supermoves: state.supermoves
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
                        sequenceMoves: state.sequenceMoves,
                        supermoves: state.supermoves
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
        switch secondTapLocation.category {
        case .foundation:
            // doesn't matter which foundation was tapped; if it can move, move it
            if card.canGoOn(state.layout.foundations) {
                let card = state.layout.surrenderCard(from: firstTapLocation)
                state.layout.foundations.accept(card: card)
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
        case .column:
            switch firstTapLocation.category {
            case .foundation: break // shouldn't happen
            case .freeCell:
                if card.canGoOn(state.layout.columns[secondTapLocation.index]) {
                    let card = state.layout.surrenderCard(from: firstTapLocation)
                    state.layout.columns[secondTapLocation.index].accept(card: card)
                }
            case .column:
                let number = state.layout.howManyCardsCanMoveLegally(
                    from: firstTapLocation.index,
                    to: secondTapLocation.index,
                    sequenceMoves: state.sequenceMoves,
                    supermoves: state.supermoves
                )
                if number > 0 {
                    state.layout.columns[firstTapLocation.index].cards.suffix(number).forEach {
                        state.layout.columns[secondTapLocation.index].accept(card: $0)
                    }
                    state.layout.columns[firstTapLocation.index].cards.removeLast(number)
                }
            }
        }
        if state.layout != oldLayout {
            state.undoStack.append(oldLayout)
            state.redoStack = []
        }
        await ensureNeutralState()
        if state.autoplay {
            await autoplay()
        }
    }

    func checkTheStopwatch() async {
        if state.gameIsOver {
            await stopwatch.stop()
            if state.gameInProgress {
                state.gameInProgress = false
                await presenter?.receive(.confetti)
            }
            return
        }
        switch stopwatch.state {
        case .paused:
            await stopwatch.resumeIfPaused()
        case .running:
            await stopwatch.advance()
        case .stopped:
            await stopwatch.start()
        }
    }
}

extension GameProcessor: StopwatchDelegate {
    func stopwatchDidUpdate(_ timeInterval: TimeInterval) async {
        await presenter?.receive(.updateStopwatch(timeInterval))
    }
}
