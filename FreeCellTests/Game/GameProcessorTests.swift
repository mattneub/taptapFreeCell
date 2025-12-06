@testable import TTFreeCell
import Testing
import Foundation
import WaitWhile

private struct GameProcessorTests {
    let subject = GameProcessor()
    let presenter = MockReceiverPresenter<GameEffect, GameState>()
    let stopwatch = MockStopwatch()
    let animator = MockAnimator()
    let lifetime = MockLifetime()
    let persistence = MockPersistence()
    let coordinator = MockRootCoordinator()
    let stats = MockStats()
    let deckFactory = MockDeckFactory()

    init() {
        subject.coordinator = coordinator
        subject.presenter = presenter
        subject.stopwatch = stopwatch
        subject.animator = animator
        services.lifetime = lifetime
        services.persistence = persistence
        services.stats = stats
        services.dateType = MockDate.self
        services.deckFactory = deckFactory
    }

    @Test("receive autoplay: plays all can-go non-needed from columns and freecells to foundations, updates undo/redo")
    func autoplay() async {
        subject.state.gameProgress = .inProgress
        var layout = Layout()
        layout.foundations[0].cards = [
            Card(rank: .ace, suit: .spades),
            Card(rank: .two, suit: .spades)
        ]
        layout.columns[0].cards = [
            Card(rank: .two, suit: .clubs),
            Card(rank: .ace, suit: .clubs)
        ]
        layout.columns[1].cards = [
            Card(rank: .three, suit: .spades),
        ]
        layout.freeCells[0].cards = [Card(rank: .two, suit: .hearts)]
        layout.freeCells[1].cards = [Card(rank: .ace, suit: .hearts)]
        subject.state.layout = layout
        subject.state.firstTapLocation = Location(category: .column, index: 0)
        subject.state.redoStack = [Layout()]
        subject.state.layout.moveCode = "heyho"
        let oldLayout = layout
        await subject.receive(.autoplay)
        #expect(subject.state.layout.foundations[0].cards == [
            Card(rank: .ace, suit: .spades),
            Card(rank: .two, suit: .spades)
        ]) // did not autoplay the three, it might be needed
        #expect(subject.state.layout.foundations[1].cards == [
            Card(rank: .ace, suit: .hearts),
            Card(rank: .two, suit: .hearts)
        ]) // from the free cells
        #expect(subject.state.layout.foundations[2].cards == [
            Card(rank: .ace, suit: .clubs),
            Card(rank: .two, suit: .clubs)

        ]) // autoplayed the ace, then the two in another round
        #expect(subject.state.layout.columns[0].isEmpty)
        #expect(subject.state.layout.columns[1].cards == [Card(rank: .three, suit: .spades)])
        #expect(subject.state.layout.freeCells.allSatisfy { $0.card == nil })
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.enablements == subject.state.baseEnablements)
        #expect(subject.state.undoStack.last == oldLayout)
        #expect(subject.state.redoStack.isEmpty)
        #expect(subject.state.layout.moveCode == nil)
        #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
        #expect(animator.oldLayout == oldLayout)
        #expect(animator.newLayout == subject.state.layout)
        #expect(animator.speed == subject.state.animationSpeed)
        #expect(stopwatch.methodsCalled == ["advance()"])
    }

    @Test("receive autoplay: with nothing to do, does nothing except return to neutral state")
    func autoplayNothingToDo() async {
        subject.state.gameProgress = .inProgress
        var layout = Layout()
        layout.columns[1].cards = [
            Card(rank: .three, suit: .spades),
        ]
        subject.state.layout = layout
        subject.state.layout.moveCode = "heyho"
        subject.state.firstTapLocation = Location(category: .column, index: 0)
        subject.state.redoStack = [Layout()]
        let oldLayout = layout
        await subject.receive(.autoplay)
        #expect(subject.state.layout == oldLayout)
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.enablements == subject.state.baseEnablements)
        #expect(subject.state.undoStack.isEmpty)
        #expect(subject.state.redoStack == [Layout()])
        #expect(subject.state.layout.moveCode == "heyho")
        #expect(animator.methodsCalled.isEmpty)
        #expect(stopwatch.methodsCalled == ["advance()"])
    }

    @Test("receive deal: creates a new full-deal layout, puts it in the state, and presents it, empties undo/redo")
    func deal() async {
        stopwatch.elapsedTime = 200
        let deck = MockDeck()
        deckFactory.mockDeckToReturn = deck
        deck.cardsToDeal = [Card(rank: .jack, suit: .hearts)]
        subject.state.gameProgress = .gameOver
        subject.state.firstTapLocation = Location(category: .column, index: 0)
        subject.state.undoStack = [Layout(), Layout()]
        subject.state.redoStack = [Layout(), Layout()]
        subject.state.layout.moveCode = "yoho"
        #expect(subject.state.layout == Layout())
        await subject.receive(.deal)
        #expect(deck.methodsCalled == ["shuffle()", "deal()"])
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.enablements == subject.state.baseEnablements)
        #expect(presenter.statesPresented == [subject.state])
        #expect(subject.state.undoStack.isEmpty)
        #expect(subject.state.redoStack.isEmpty)
        #expect(subject.state.layout.moveCode == nil)
        #expect(subject.state.gameProgress == .dealtWaitingForFirstMove)
        #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
        #expect(animator.oldLayout == Layout()) // special signal indicating that this is a deal
        #expect(animator.newLayout == subject.state.layout)
        #expect(animator.speed == subject.state.animationSpeed)
        #expect(stopwatch.methodsCalled == ["reset(to:)"])
        #expect(stopwatch.resetTimeInterval == 0)
    }

    @Test("receive deal: if game is not gameOver, puts up alert; if user cancels, stops")
    func dealNotWaitingForDeal() async {
        subject.state.gameProgress = .inProgress
        coordinator.buttonTitleToReturn = "Cancel"
        await subject.receive(.deal)
        #expect(coordinator.methodsCalled == ["showAlert(title:message:buttonTitles:)"])
        #expect(coordinator.title == "Really Deal?")
        #expect(coordinator.message == "You have not yet finished the current game. Do you really want to lose this game and deal another game?")
        #expect(coordinator.buttonTitles == ["Cancel", "Deal"])
        #expect(subject.state.layout == Layout())
        #expect(presenter.statesPresented.isEmpty)
        #expect(animator.methodsCalled.isEmpty)
        #expect(stopwatch.methodsCalled.isEmpty)
        #expect(stats.methodsCalled.isEmpty)
    }

    @Test("receive deal: deals repeatedly until layout tableau description is not in stats")
    func dealRepeatedly() async {
        let deck = MockDeck()
        deckFactory.mockDeckToReturn = deck
        deck.cardsToDeal = [
            Card(rank: .jack, suit: .hearts),
            Card(rank: .queen, suit: .hearts),
            Card(rank: .king, suit: .hearts)
        ]
        var stats = StatsDictionary()
        let stat = Stat(dateFinished: Date.now, won: true, initialLayout: Layout(), movesCount: 1, timeTaken: 1)
        var layout = Layout()
        layout.columns[0].cards = [deck.cardsToDeal[0]]
        stats[layout.tableauDescription] = stat
        layout.columns[0].cards = [deck.cardsToDeal[1]]
        stats[layout.tableauDescription] = stat
        // okay, we've stacked the deck (ha ha), here comes the test
        self.stats.stats = stats
        await subject.receive(.deal)
        #expect(deck.methodsCalled == ["shuffle()", "deal()", "shuffle()", "deal()", "shuffle()", "deal()"])
    }

    @Test("receive deal: if game is not gameOver, puts up alert; if user does not cancel, saves lost game, proceeds to deal")
    func dealNotWaitingForDealUserSaysDeal() async {
        let deck = MockDeck()
        deckFactory.mockDeckToReturn = deck
        deck.cardsToDeal = [Card(rank: .jack, suit: .hearts)]
        stopwatch.elapsedTime = 200
        subject.state.gameProgress = .inProgress
        coordinator.buttonTitleToReturn = "Deal"
        var layout1 = Layout()
        layout1.columns[0].cards = [Card(rank: .jack, suit: .hearts)]
        var layout2 = Layout()
        layout2.moveCode = "hey"
        subject.state.undoStack = [
            layout1,
            layout2
        ]
        subject.state.layout.moveCode = "ho"
        await subject.receive(.deal)
        #expect(coordinator.title == "Really Deal?")
        #expect(coordinator.message == "You have not yet finished the current game. Do you really want to lose this game and deal another game?")
        #expect(coordinator.buttonTitles == ["Cancel", "Deal"])
        await #while(stats.methodsCalled.isEmpty)
        #expect(stats.methodsCalled == ["saveStat(_:)"])
        #expect(stats.stat == Stat(
            dateFinished: Date.distantPast,
            won: false,
            initialLayout: layout1,
            movesCount: 2,
            timeTaken: 200,
            codes: ["hey", "ho"]
        ))
        #expect(deck.methodsCalled == ["shuffle()", "deal()"])
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.enablements == subject.state.baseEnablements)
        #expect(presenter.statesPresented == [subject.state])
        #expect(subject.state.undoStack.isEmpty)
        #expect(subject.state.redoStack.isEmpty)
        #expect(subject.state.layout.moveCode == nil)
        #expect(subject.state.gameProgress == .dealtWaitingForFirstMove)
        #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
        #expect(animator.oldLayout == Layout()) // special signal indicating that this is a deal
        #expect(animator.newLayout == subject.state.layout)
        #expect(animator.speed == subject.state.animationSpeed)
        #expect(stopwatch.methodsCalled == ["reset(to:)"])
        #expect(stopwatch.resetTimeInterval == 0)
    }

    @Test("receive didInitialLayout: sets up the lifetime listener task, tells stats to load stats")
    func didInitialLayout() async {
        #expect(subject.listenForEventTask == nil)
        await subject.receive(.didInitialLayout)
        await #while(subject.listenForEventTask == nil)
        #expect(subject.listenForEventTask != nil)
        #expect(stats.methodsCalled == ["loadStats()"])
        subject.listenForEventTask?.cancel()
    }

    @Test("receive didInitialLayout: setting the lifetime's becomeActive calls the stopwatch resumeIfPaused")
    func didInitialLayoutBecomeActive() async {
        await subject.receive(.didInitialLayout)
        await #while(subject.listenForEventTask == nil)
        Task {
            lifetime.event = .becomeActive
        }
        await #while(stopwatch.methodsCalled.isEmpty)
        #expect(stopwatch.methodsCalled == ["resumeIfPaused()"])
        subject.listenForEventTask?.cancel()
    }

    @Test("receive didInitialLayout: setting the lifetime's resignActive calls the stopwatch pause")
    func didInitialLayoutResignActive() async {
        await subject.receive(.didInitialLayout)
        await #while(subject.listenForEventTask == nil)
        Task {
            lifetime.event = .resignActive
        }
        await #while(stopwatch.methodsCalled.isEmpty)
        #expect(stopwatch.methodsCalled == ["pause()"])
        subject.listenForEventTask?.cancel()
    }

    @Test("receive didInitialLayout: setting the lifetime's enterBackground sends remove confetti, tells persistence to save game")
    func didInitialLayoutEnterBackground() async {
        await subject.receive(.didInitialLayout)
        await #while(subject.listenForEventTask == nil)
        Task {
            lifetime.event = .enterBackground
        }
        await #while(persistence.methodsCalled.count < 2) // because loadGame is called first!
        #expect(persistence.methodsCalled.last == "saveGame(_:)")
        #expect(presenter.thingsReceived == [.removeConfetti])
    }

    @Test("receive didInitialLayout: restores game if there is one saved")
    func didInitialLayoutRestoreGame() async {
        var layout = Layout()
        layout.columns[0].cards = [Card(rank: .six, suit: .spades)]
        let savedGame = SavedGame(
            layout: layout,
            undoStack: [Layout(), Layout(), Layout()],
            redoStack: [Layout(), Layout()],
            timeTaken: 3
        )
        persistence.savedGameToReturn = savedGame
        await subject.receive(.didInitialLayout)
        #expect(subject.state.layout == layout)
        #expect(subject.state.undoStack == [Layout(), Layout(), Layout()])
        #expect(subject.state.redoStack == [Layout(), Layout()])
        #expect(subject.state.gameProgress == .dealtWaitingForFirstMove) // *
        #expect(presenter.statesPresented == [subject.state])
        #expect(stopwatch.methodsCalled == ["reset(to:)"])
        #expect(stopwatch.resetTimeInterval == 3)
    }

    @Test("receive didInitialLayout: restores game if there is one saved and that game is over")
    func didInitialLayoutRestoreGameOver() async {
        var layout = Layout()
        layout.foundations[0].cards = [Card(rank: .six, suit: .spades)]
        let savedGame = SavedGame(
            layout: layout,
            undoStack: [Layout(), Layout(), Layout()],
            redoStack: [Layout(), Layout()],
            timeTaken: 3
        )
        persistence.savedGameToReturn = savedGame
        await subject.receive(.didInitialLayout)
        #expect(subject.state.layout == layout)
        #expect(subject.state.undoStack == [Layout(), Layout(), Layout()])
        #expect(subject.state.redoStack == [Layout(), Layout()])
        #expect(subject.state.gameProgress == .gameOver) // *
        #expect(presenter.statesPresented == [subject.state])
        #expect(stopwatch.methodsCalled == ["reset(to:)"])
        #expect(stopwatch.resetTimeInterval == 3)
    }

    @Test("receive hint: enables freecells and columns that can move nontrivially")
    func hint() async {
        subject.state.gameProgress = .inProgress
        subject.state.layout.foundations[0].cards = [Card(rank: .six, suit: .spades)]
        subject.state.layout.freeCells[0].cards = [Card(rank: .seven, suit: .spades)]
        subject.state.layout.freeCells[1].cards = [Card(rank: .two, suit: .clubs)]
        subject.state.layout.freeCells[2].cards = [Card(rank: .king, suit: .hearts)]
        subject.state.layout.columns[0].cards = [Card(rank: .eight, suit: .hearts), Card(rank: .seven, suit: .spades)]
        subject.state.layout.columns[1].cards = [Card(rank: .six, suit: .hearts)]
        subject.state.layout.columns[2].cards = [Card(rank: .three, suit: .hearts)]
        subject.state.layout.columns[3].cards = [Card(rank: .five, suit: .diamonds), Card(rank: .four, suit: .spades)]
        var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
        expected[Location(category: .freeCell, index: 0)] = .enabled // seven can go on six in foundations
        expected[Location(category: .freeCell, index: 1)] = .enabled // two can go on three in column 2
        expected[Location(category: .column, index: 0)] = .enabled // seven can go on six in foundations
        expected[Location(category: .column, index: 1)] = .enabled // six can go on seven in column 0
        expected[Location(category: .column, index: 2)] = .enabled // three can go on four in column 3
        await subject.receive(.hint)
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.enablements == expected)
        #expect(presenter.statesPresented == [subject.state])
        #expect(stopwatch.methodsCalled == ["advance()"])
    }

    @Test("receive longPress: sends tint with all cards of same rank")
    func longPress() async throws {
        subject.state.firstTapLocation = Location(category: .freeCell, index: 1)
        subject.state.layout.foundations[0].cards = [Card(rank: .six, suit: .spades)]
        subject.state.layout.freeCells[0].cards = [Card(rank: .seven, suit: .spades)]
        subject.state.layout.freeCells[1].cards = [Card(rank: .two, suit: .clubs)]
        subject.state.layout.freeCells[2].cards = [Card(rank: .king, suit: .hearts)]
        subject.state.layout.columns[0].cards = [Card(rank: .eight, suit: .hearts), Card(rank: .seven, suit: .spades)]
        subject.state.layout.columns[1].cards = [Card(rank: .seven, suit: .clubs), Card(rank: .six, suit: .hearts)]
        subject.state.layout.columns[2].cards = [Card(rank: .three, suit: .hearts)]
        subject.state.layout.columns[3].cards = [Card(rank: .six, suit: .diamonds), Card(rank: .five, suit: .spades)]
        await subject.receive(.longPress(Location(category: .foundation, index: 0), -1))
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.enablements == subject.state.baseEnablements)
        #expect(presenter.statesPresented == [subject.state])
        let expected: [LocationAndCard] = [
            LocationAndCard(location: Location(category: .foundation, index: 0), internalIndex: 0, card: Card(rank: .six, suit: .spades)),
            LocationAndCard(location: Location(category: .column, index: 1), internalIndex: 1, card: Card(rank: .six, suit: .hearts)),
            LocationAndCard(location: Location(category: .column, index: 3), internalIndex: 0, card: Card(rank: .six, suit: .diamonds)),
        ]
        #expect(presenter.thingsReceived == [.tint(expected)])
        print(presenter.thingsReceived)
    }

    @Test("receive longPressEnded: sends tintsOff")
    func longPressEnded() async {
        subject.state.gameProgress = .inProgress
        subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
        await subject.receive(.longPressEnded)
        #expect(presenter.thingsReceived == [.tintsOff])
        #expect(stopwatch.methodsCalled == ["advance()"])
    }

    @Test("receive redo: if redo stack not empty, move one redo layout to layout and layout to undo")
    func redo() async {
        subject.state.gameProgress = .inProgress
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            let oldState = subject.state
            await subject.receive(.redo)
            #expect(subject.state == oldState)
            #expect(subject.state.undoStack.isEmpty)
            #expect(presenter.statesPresented.isEmpty)
            #expect(animator.methodsCalled.isEmpty)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        stopwatch.methodsCalled = []
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            let oldLayout = subject.state.layout
            var redoLayout1 = Layout()
            redoLayout1.columns[1].cards = [Card(rank: .queen, suit: .hearts)]
            var redoLayout2 = Layout()
            redoLayout2.columns[2].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.redoStack.append(redoLayout2)
            subject.state.redoStack.append(redoLayout1)
            await subject.receive(.redo)
            #expect(subject.state.undoStack.first?.columns[0].cards == [Card(rank: .queen, suit: .hearts)])
            #expect(subject.state.layout.columns[0].cards == [])
            #expect(subject.state.layout.columns[1].cards == [Card(rank: .queen, suit: .hearts)])
            #expect(subject.state.redoStack.last?.columns[0].cards == [])
            #expect(subject.state.redoStack.last?.columns[1].cards == [])
            #expect(subject.state.redoStack.last?.columns[2].cards == [Card(rank: .queen, suit: .hearts)])
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
            #expect(animator.oldLayout == oldLayout)
            #expect(animator.newLayout == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("receive redoAll: if redo stack not empty, moves redo layouts to undo, last one to layout")
    func redoAll() async {
        subject.state.gameProgress = .inProgress
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            let oldState = subject.state
            await subject.receive(.redoAll)
            #expect(subject.state == oldState)
            #expect(subject.state.undoStack.isEmpty)
            #expect(presenter.statesPresented.isEmpty)
            #expect(animator.methodsCalled.isEmpty)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        stopwatch.methodsCalled = []
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            let oldLayout = subject.state.layout
            var redoLayout1 = Layout()
            redoLayout1.columns[1].cards = [Card(rank: .queen, suit: .hearts)]
            var redoLayout2 = Layout()
            redoLayout2.columns[2].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.redoStack.append(redoLayout2)
            subject.state.redoStack.append(redoLayout1)
            await subject.receive(.redoAll)
            #expect(subject.state.undoStack.first?.columns[0].cards == [Card(rank: .queen, suit: .hearts)])
            #expect(subject.state.undoStack.last?.columns[0].cards == [])
            #expect(subject.state.undoStack.last?.columns[1].cards == [Card(rank: .queen, suit: .hearts)])
            #expect(subject.state.layout.columns[0].cards == [])
            #expect(subject.state.layout.columns[1].cards == [])
            #expect(subject.state.layout.columns[2].cards == [Card(rank: .queen, suit: .hearts)])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
            #expect(animator.oldLayout == oldLayout)
            #expect(animator.newLayout == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("receive showHelp: pauses the stopwatch, tells coordinator")
    func showHelp() async {
        await subject.receive(.showHelp)
        #expect(stopwatch.methodsCalled == ["pause()"])
        #expect(coordinator.methodsCalled == ["showHelp(_:)"])
        #expect(coordinator.helpType == .help)
    }

    @Test("receive showRules: pauses the stopwatch, tells coordinator")
    func showRules() async {
        await subject.receive(.showRules)
        #expect(stopwatch.methodsCalled == ["pause()"])
        #expect(coordinator.methodsCalled == ["showHelp(_:)"])
        #expect(coordinator.helpType == .rules)
    }

    @Test("receive showStats: pauses the stopwatch, tells coordinator")
    func showStats() async {
        await subject.receive(.showStats)
        #expect(stopwatch.methodsCalled == ["pause()"])
        #expect(coordinator.methodsCalled == ["showStats()"])
    }

    @Test("receive tapBackground: erases existing first tap, returns to neutrality")
    func tapBackground() async {
        subject.state.gameProgress = .inProgress
        subject.state.firstTapLocation = Location(category: .column, index: 0)
        subject.state.layout.columns[0].cards = [Card(rank: .five, suit: .hearts)]
        await subject.receive(.tapBackground)
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.enablements == subject.state.baseEnablements)
        #expect(presenter.statesPresented == [subject.state])
        #expect(stopwatch.methodsCalled == ["advance()"])
    }

    @Test("tapped: if firstTapLocation is nil, tapped location becomes firstTapLocation if not empty source, not foundation")
    func tappedFirst() async {
        subject.state.gameProgress = .inProgress
        do {
            subject.state.layout.columns[7].cards = [Card(rank: .five, suit: .hearts)]
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(presenter.statesPresented == [subject.state])
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        stopwatch.methodsCalled = []
        do {
            subject.state.layout.columns[7].cards = [Card(rank: .five, suit: .hearts)]
            subject.state.layout.foundations[0].cards = [Card(rank: .ace, suit: .spades)]
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .foundation, index: 0)))
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(presenter.statesPresented == [subject.state])
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        stopwatch.methodsCalled = []
        do {
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.unambiguousMove = false
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.firstTapLocation == Location(category: .column, index: 0))
            #expect(subject.state.enablements != subject.state.baseEnablements)
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(presenter.statesPresented == [subject.state])
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("tapped: if firstTapLocation is nil, if card can be autoplayed, it is, followed by autoplay if enabled, undo/redo")
    func tappedFirstCanAutoplay() async {
        subject.state.gameProgress = .inProgress
        do {
            subject.state.layout.columns[0].cards = [
                Card(rank: .two, suit: .clubs),
                Card(rank: .ace, suit: .clubs),
            ]
            subject.state.layout.moveCode = "heyho"
            let oldLayout = subject.state.layout
            subject.state.autoplay = false // we will play just the ace and stop
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.layout.foundation(for: .clubs).cards == [Card(rank: .ace, suit: .clubs)])
            #expect(subject.state.layout.columns[0].cards == [Card(rank: .two, suit: .clubs)])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.layout.moveCode == nil)
            #expect(subject.state.undoStack.last?.columns[0].cards == [
                Card(rank: .two, suit: .clubs),
                Card(rank: .ace, suit: .clubs),
            ])
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
            #expect(animator.oldLayout == oldLayout)
            #expect(animator.newLayout == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        stopwatch.methodsCalled = []
        animator.methodsCalled = []
        animator.oldLayouts = []
        animator.newLayouts = []
        do {
            subject.state.layout.columns[0].cards = [
                Card(rank: .two, suit: .clubs),
                Card(rank: .ace, suit: .clubs),
            ]
            subject.state.layout.columns[7].cards = [Card(rank: .seven, suit: .clubs)]
            subject.state.layout.moveCode = "heyho"
            let oldLayout = subject.state.layout
            subject.state.autoplay = true // we will play and then autoplay
            subject.state.redoStack = [Layout]()
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.layout.foundation(for: .clubs).cards == [
                Card(rank: .ace, suit: .clubs),
                Card(rank: .two, suit: .clubs)
            ])
            #expect(subject.state.layout.columns[0].cards == [])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.layout.moveCode == nil)
            #expect(subject.state.undoStack.first?.columns[0].cards == [
                Card(rank: .two, suit: .clubs),
                Card(rank: .ace, suit: .clubs),
            ])
            #expect(subject.state.undoStack.last?.columns[0].cards == [
                Card(rank: .two, suit: .clubs),
            ])
            #expect(subject.state.undoStack.last?.foundation(for: .clubs).cards == [
                Card(rank: .ace, suit: .clubs)
            ])
            // two rounds of animation
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)", "animate(oldLayout:newLayout:speed:)"])
            let middleLayout = subject.state.undoStack.last!
            #expect(animator.oldLayouts[0] == oldLayout)
            #expect(animator.newLayouts[0] == middleLayout)
            #expect(animator.oldLayouts[1] == middleLayout)
            #expect(animator.newLayouts[1] == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(presenter.statesPresented.last == subject.state)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("tapped: if valid first tap, enablements are set or not depending on showDestinations")
    func showDestinations() async {
        subject.state.gameProgress = .inProgress
        do {
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .clubs)]
            subject.state.showDestinations = false
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.firstTapLocation == Location(category: .column, index: 0))
            #expect(presenter.statesPresented[0] == subject.state)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        stopwatch.methodsCalled = []
        do {
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .clubs)]
            subject.state.showDestinations = true // default
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.enablements != subject.state.baseEnablements)
            #expect(subject.state.firstTapLocation == Location(category: .column, index: 0))
            #expect(presenter.statesPresented[0] == subject.state)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("tapped: first tap enablements are right for column tapped")
    func enablementsColumn() async {
        subject.state.gameProgress = .inProgress
        do {
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .clubs)]
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            expected[Location(category: .column, index: 1)] = .enabled
            (0..<4).forEach { expected[Location(category: .freeCell, index: $0)] = .enabled }
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == Location(category: .column, index: 0))
            #expect(presenter.statesPresented == [subject.state])
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        stopwatch.methodsCalled = []
        do {
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .clubs)]
            subject.state.layout.foundations[1].cards = [Card(rank: .jack, suit: .hearts)]
            subject.state.layout.freeCells[0].cards = [Card(rank: .two, suit: .clubs)]
            subject.state.layout.freeCells[1].cards = [Card(rank: .two, suit: .clubs)]
            subject.state.layout.freeCells[2].cards = [Card(rank: .two, suit: .clubs)]
            subject.state.layout.freeCells[3].cards = [Card(rank: .two, suit: .clubs)]
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            expected[Location(category: .column, index: 1)] = .enabled
            (0..<4).forEach { expected[Location(category: .foundation, index: $0)] = .enabled }
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == Location(category: .column, index: 0))
            #expect(presenter.statesPresented == [subject.state])
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("tapped: first tap enablements are right for freeCell tapped")
    func enablementsFreeCell() async {
        subject.state.gameProgress = .inProgress
        do {
            subject.state.layout.freeCells[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .clubs)]
            subject.state.layout.columns[2].cards = [Card(rank: .king, suit: .diamonds)]
            await subject.receive(.tapped(Location(category: .freeCell, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            (0..<8).forEach { expected[Location(category: .column, index: $0)] = .enabled }
            expected[Location(category: .column, index: 2)] = .disabled
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == Location(category: .freeCell, index: 0))
            #expect(presenter.statesPresented == [subject.state])
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        stopwatch.methodsCalled = []
        do {
            subject.state.layout.freeCells[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .clubs)]
            subject.state.layout.columns[2].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.foundations[1].cards = [Card(rank: .jack, suit: .hearts)]
            await subject.receive(.tapped(Location(category: .freeCell, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            (0..<4).forEach { expected[Location(category: .foundation, index: $0)] = .enabled }
            (0..<8).forEach { expected[Location(category: .column, index: $0)] = .enabled }
            expected[Location(category: .column, index: 2)] = .disabled
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == Location(category: .freeCell, index: 0))
            #expect(presenter.statesPresented == [subject.state])
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("tapped: if firstTapLocation is nil, if state unambiguousMove is true, if no unambiguous move, acts normally")
    func tapFirstUnambiguousNone() async {
        subject.state.gameProgress = .inProgress
        do {
            subject.state.layout.freeCells[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .clubs)]
            subject.state.layout.columns[2].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.moveCode = "heyho"
            subject.state.unambiguousMove = true
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .freeCell, index: 0)))
            #expect(subject.state.layout == oldLayout)
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            (0..<8).forEach { expected[Location(category: .column, index: $0)] = .enabled }
            expected[Location(category: .column, index: 2)] = .disabled
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == Location(category: .freeCell, index: 0))
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(subject.state.layout.moveCode == "heyho")
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled.isEmpty)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        stopwatch.methodsCalled = []
        do {
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .clubs)]
            subject.state.unambiguousMove = true
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            subject.state.layout.moveCode = "heyho"
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.firstTapLocation == Location(category: .column, index: 0))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            expected[Location(category: .column, index: 1)] = .enabled
            (0..<4).forEach { expected[Location(category: .freeCell, index: $0)] = .enabled }
            #expect(subject.state.enablements == expected)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(subject.state.layout.moveCode == "heyho")
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled.isEmpty)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("tapped: if firstTapLocation is nil, if state unambiguousMove is true, if unambiguous move, makes it, undo/redo, move code")
    func tapFirstUnambiguousYesFreeCell() async {
        subject.state.gameProgress = .inProgress
        do {
            subject.state.layout.foundations[1].cards = [Card(rank: .jack, suit: .hearts)]
            subject.state.layout.freeCells[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[2].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [Card(rank: .ace, suit: .diamonds)]
            subject.state.layout.columns[0].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.moveCode = "heyho"
            subject.state.unambiguousMove = false
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .freeCell, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            expected[Location(category: .foundation, index: 0)] = .enabled
            expected[Location(category: .foundation, index: 1)] = .enabled
            expected[Location(category: .foundation, index: 2)] = .enabled
            expected[Location(category: .foundation, index: 3)] = .enabled
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == Location(category: .freeCell, index: 0))
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(subject.state.layout.moveCode == "heyho")
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled.isEmpty)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        stopwatch.methodsCalled = []
        do {
            subject.state.layout.foundations[1].cards = [Card(rank: .jack, suit: .hearts)]
            subject.state.layout.freeCells[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[2].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [Card(rank: .ace, suit: .diamonds)]
            subject.state.layout.columns[0].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.moveCode = "heyho"
            subject.state.unambiguousMove = true // *
            let oldLayout = subject.state.layout
            await subject.receive(.tapped(Location(category: .freeCell, index: 0)))
            #expect(subject.state.layout.foundations[1].cards == [
                Card(rank: .jack, suit: .hearts),
                Card(rank: .queen, suit: .hearts),
            ])
            #expect(subject.state.layout.freeCells[0].isEmpty)
            #expect(subject.state.layout.columns[7].isEmpty) // because there was a round of autoplay
            #expect(subject.state.layout.foundations[3].cards == [Card(rank: .ace, suit: .diamonds)])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.first == oldLayout)
            #expect(subject.state.undoStack.last?.columns[7].cards == [Card(rank: .ace, suit: .diamonds)])
            // because that change happened in the round of autoplay
            #expect(subject.state.undoStack.last?.moveCode == "ah") // because the _user_ moved queen to foundation
            #expect(subject.state.layout.moveCode == nil) // because the autoplay move is not the user
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.firstTapLocation == nil)
            #expect(presenter.statesPresented.last == subject.state)
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)", "animate(oldLayout:newLayout:speed:)"])
            let middleLayout = subject.state.undoStack.last!
            #expect(animator.oldLayouts[0] == oldLayout)
            #expect(animator.newLayouts[0] == middleLayout)
            #expect(animator.oldLayouts[1] == middleLayout)
            #expect(animator.newLayouts[1] == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        stopwatch.methodsCalled = []
        animator.methodsCalled = []
        animator.oldLayouts = []
        animator.newLayouts = []
        do {
            subject.state.layout.freeCells[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .clubs)]
            subject.state.layout.columns[2].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [Card(rank: .ace, suit: .diamonds)]
            subject.state.layout.columns[0].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.moveCode = "heyho"
            subject.state.unambiguousMove = false
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            let oldLayout = subject.state.layout
            await subject.receive(.tapped(Location(category: .freeCell, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            expected[Location(category: .column, index: 1)] = .enabled
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == Location(category: .freeCell, index: 0))
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(subject.state.layout.moveCode == "heyho")
            #expect(presenter.statesPresented == [subject.state])
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        stopwatch.methodsCalled = []
        animator.methodsCalled = []
        animator.oldLayouts = []
        animator.newLayouts = []
        do {
            subject.state.layout.freeCells[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .clubs)]
            subject.state.layout.columns[2].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [Card(rank: .ace, suit: .diamonds)]
            subject.state.layout.columns[0].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.moveCode = "heyho"
            subject.state.unambiguousMove = true // *
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .freeCell, index: 0)))
            #expect(subject.state.layout.freeCells[0].isEmpty)
            #expect(subject.state.layout.columns[1].cards == [
                Card(rank: .king, suit: .clubs),
                Card(rank: .queen, suit: .hearts),
            ])
            #expect(subject.state.layout.columns[7].isEmpty)
            #expect(subject.state.layout.foundations[3].cards == [Card(rank: .ace, suit: .diamonds)])
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.first == oldLayout)
            #expect(subject.state.undoStack.last?.columns[7].cards == [Card(rank: .ace, suit: .diamonds)])
            #expect(subject.state.undoStack.last?.moveCode == "a2") // user moved queen onto king of club
            #expect(subject.state.layout.moveCode == nil) // computer autoplayed
            #expect(presenter.statesPresented.last == subject.state)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    // same idea as preceding except that the tap is a column instead of a freecell
    @Test("tapped: if firstTapLocation is nil, if state unambiguousMove is true, if unambiguous move, makes it, undo/redo")
    func tapFirstUnambiguousYesColumn() async {
        subject.state.gameProgress = .inProgress
        do {
            subject.state.layout.foundations[1].cards = [Card(rank: .jack, suit: .hearts)]
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[2].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [Card(rank: .ace, suit: .diamonds)]
            subject.state.layout.freeCells[0].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[1].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[2].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[3].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.moveCode = "heyho"
            subject.state.unambiguousMove = false
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            expected[Location(category: .foundation, index: 0)] = .enabled
            expected[Location(category: .foundation, index: 1)] = .enabled
            expected[Location(category: .foundation, index: 2)] = .enabled
            expected[Location(category: .foundation, index: 3)] = .enabled
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == Location(category: .column, index: 0))
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(subject.state.layout.moveCode == "heyho")
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled.isEmpty)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        stopwatch.methodsCalled = []
        animator.methodsCalled = []
        animator.oldLayouts = []
        animator.newLayouts = []
        do {
            subject.state.layout.foundations[1].cards = [Card(rank: .jack, suit: .hearts)]
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[2].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [Card(rank: .ace, suit: .diamonds)]
            subject.state.layout.freeCells[0].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[1].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[2].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[3].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.moveCode = "heyho"
            subject.state.unambiguousMove = true
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            let expected: [Card] = [
                Card(rank: .jack, suit: .hearts),
                Card(rank: .queen, suit: .hearts)
            ]
            #expect(subject.state.layout.foundations[1].cards == expected)
            #expect(subject.state.layout.columns[0].cards == [])
            #expect(subject.state.layout.columns[7].cards == [])
            #expect(subject.state.layout.foundations[3].cards == [Card(rank: .ace, suit: .diamonds)])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.first == oldLayout)
            #expect(subject.state.undoStack.last?.columns[7].cards == [Card(rank: .ace, suit: .diamonds)])
            #expect(subject.state.undoStack.last?.moveCode == "1h")
            #expect(subject.state.layout.moveCode == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.firstTapLocation == nil)
            #expect(presenter.statesPresented.last == subject.state)
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)", "animate(oldLayout:newLayout:speed:)"])
            let middleLayout = subject.state.undoStack.last!
            #expect(animator.oldLayouts[0] == oldLayout)
            #expect(animator.newLayouts[0] == middleLayout)
            #expect(animator.oldLayouts[1] == middleLayout)
            #expect(animator.newLayouts[1] == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        stopwatch.methodsCalled = []
        animator.methodsCalled = []
        animator.oldLayouts = []
        animator.newLayouts = []
        do {
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .clubs)]
            subject.state.layout.columns[2].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [Card(rank: .ace, suit: .diamonds)]
            subject.state.layout.freeCells[0].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[1].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[2].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[3].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.moveCode = "heyho"
            subject.state.unambiguousMove = false
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            expected[Location(category: .column, index: 1)] = .enabled
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(subject.state.layout.moveCode == "heyho")
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == Location(category: .column, index: 0))
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled.isEmpty)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        stopwatch.methodsCalled = []
        animator.methodsCalled = []
        animator.oldLayouts = []
        animator.newLayouts = []
        do {
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .king, suit: .clubs)]
            subject.state.layout.columns[2].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [Card(rank: .ace, suit: .diamonds)]
            subject.state.layout.freeCells[0].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[1].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[2].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[3].cards = [Card(rank: .king, suit: .diamonds)]
            subject.state.layout.moveCode = "heyho"
            subject.state.unambiguousMove = true // *
            subject.state.redoStack = [Layout()]
            let oldLayout = subject.state.layout
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.layout.columns[0].isEmpty)
            let expected: [Card] = [
                Card(rank: .king, suit: .clubs),
                Card(rank: .queen, suit: .hearts),
            ]
            #expect(subject.state.layout.columns[1].cards == expected)
            #expect(subject.state.layout.columns[7].isEmpty)
            #expect(subject.state.layout.foundations[3].cards == [Card(rank: .ace, suit: .diamonds)])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.first == oldLayout)
            #expect(subject.state.undoStack.last?.columns[7].cards == [Card(rank: .ace, suit: .diamonds)])
            #expect(subject.state.undoStack.last?.moveCode == "12")
            #expect(subject.state.layout.moveCode == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.firstTapLocation == nil)
            #expect(presenter.statesPresented.last == subject.state)
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)", "animate(oldLayout:newLayout:speed:)"])
            let middleLayout = subject.state.undoStack.last!
            #expect(animator.oldLayouts[0] == oldLayout)
            #expect(animator.newLayouts[0] == middleLayout)
            #expect(animator.oldLayouts[1] == middleLayout)
            #expect(animator.newLayouts[1] == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        stopwatch.methodsCalled = []
        animator.methodsCalled = []
        animator.oldLayouts = []
        animator.newLayouts = []
        do {
            // much simpler example!
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.moveCode = "heyho"
            let oldLayout = subject.state.layout
            subject.state.unambiguousMove = true
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.layout.columns[0].cards.isEmpty)
            let expected: [Card] = [Card(rank: .queen, suit: .hearts)]
            #expect(subject.state.layout.freeCells[0].cards == expected)
            #expect(subject.state.layout.moveCode == "1a")
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented.last == subject.state)
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
            #expect(animator.oldLayout == oldLayout)
            #expect(animator.newLayout == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("tapped: unambiguous edge case: if there are multiple moves to empty columns, moves to first one")
    func unambiguousEdgeCase() async {
        subject.state.gameProgress = .inProgress
        do {
            subject.state.layout.freeCells[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.unambiguousMove = true
            await subject.receive(.tapped(Location(category: .freeCell, index: 0)))
            #expect(subject.state.layout.freeCells[0].isEmpty)
            #expect(subject.state.layout.columns[0].cards == [Card(rank: .queen, suit: .hearts)])
        }
        subject.state.layout = Layout()
        do {
            subject.state.layout.freeCells[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.freeCells[1].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.freeCells[2].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.freeCells[3].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[7].cards = [
                Card(rank: .three, suit: .clubs),
                Card(rank: .three, suit: .hearts)
            ]
            subject.state.unambiguousMove = true
            await subject.receive(.tapped(Location(category: .column, index: 7)))
            #expect(subject.state.layout.columns[7].cards == [Card(rank: .three, suit: .clubs)])
            #expect(subject.state.layout.columns[0].cards == [Card(rank: .three, suit: .hearts)])
        }
    }

    @Test("tapped: if firstTapLocation exists, if second location is any foundation, moves firstTapLocation card if movable")
    func tapSecondFoundation() async {
        subject.state.gameProgress = .inProgress
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [Card(rank: .six, suit: .hearts)]
            subject.state.layout.foundations[1].cards = [Card(rank: .four, suit: .hearts)]
            subject.state.layout.moveCode = "heyho"
            let oldLayout = subject.state.layout
            subject.state.autoplay = false
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .foundation, index: 0)))
            // can't put the four on the six, do nothing, end of tap-tap
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(subject.state.layout.moveCode == "heyho")
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled.isEmpty)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        stopwatch.methodsCalled = []
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [Card(rank: .six, suit: .hearts)]
            subject.state.layout.columns[7].cards = [Card(rank: .six, suit: .clubs)]
            subject.state.layout.foundations[1].cards = [Card(rank: .five, suit: .hearts)]
            subject.state.autoplay = false
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .foundation, index: 0)))
            // doesn't matter _which_ foundation the user taps on
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.layout.foundations[1].cards == [
                Card(rank: .five, suit: .hearts),
                Card(rank: .six, suit: .hearts),
            ])
            #expect(subject.state.layout.columns[0].cards.isEmpty)
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.last == oldLayout)
            #expect(subject.state.layout.moveCode == "1h")
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
            #expect(animator.oldLayout == oldLayout)
            #expect(animator.newLayout == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("tapped: if firstTappedLocation is column, if second location is any free cell, move to first empty free cell")
    func tapSecondFreecell() async {
        subject.state.gameProgress = .inProgress
        do {
            // cannot move from a freecell to a freecell
            subject.state.firstTapLocation = Location(category: .freeCell, index: 0)
            subject.state.layout.freeCells[0].cards = [Card(rank: .two, suit: .clubs)]
            subject.state.layout.columns[0].cards = [Card(rank: .six, suit: .hearts)]
            subject.state.layout.moveCode = "heyho"
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            subject.state.autoplay = false
            await subject.receive(.tapped(Location(category: .freeCell, index: 3)))
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(subject.state.layout.moveCode == "heyho")
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled.isEmpty)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        stopwatch.methodsCalled = []
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.freeCells[0].cards = [Card(rank: .two, suit: .clubs)]
            subject.state.layout.columns[0].cards = [Card(rank: .six, suit: .hearts)]
            subject.state.layout.moveCode = "heyho"
            subject.state.autoplay = false
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .freeCell, index: 3)))
            // doesn't matter which free cell is tapped second
            #expect(subject.state.layout.freeCells[1].card == Card(rank: .six, suit: .hearts))
            #expect(subject.state.layout.columns[0].cards == [])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.last == oldLayout)
            #expect(subject.state.layout.moveCode == "1b") // where it _went_, not where user _tapped_
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
            #expect(animator.oldLayout == oldLayout)
            #expect(animator.newLayout == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("tapped: if firstTapLocation is freeCell, if secondLocation is column, move it if movable")
    func tapSecondColumnFromFreeCell() async {
        subject.state.gameProgress = .inProgress
        do {
            // cannot put the two on the six
            subject.state.firstTapLocation = Location(category: .freeCell, index: 0)
            subject.state.layout.freeCells[0].cards = [Card(rank: .two, suit: .clubs)]
            subject.state.layout.columns[0].cards = [Card(rank: .six, suit: .hearts)]
            subject.state.layout.moveCode = "heyho"
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            subject.state.autoplay = false
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(subject.state.layout.moveCode == "heyho")
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled.isEmpty)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        stopwatch.methodsCalled = []
        do {
            subject.state.firstTapLocation = Location(category: .freeCell, index: 0)
            subject.state.layout.freeCells[0].cards = [Card(rank: .five, suit: .clubs)]
            subject.state.layout.columns[0].cards = [Card(rank: .six, suit: .hearts)]
            subject.state.layout.moveCode = "heyho"
            subject.state.autoplay = false
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.layout.freeCells[0].card == nil)
            #expect(subject.state.layout.columns[0].cards == [
                Card(rank: .six, suit: .hearts),
                Card(rank: .five, suit: .clubs),
            ])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.last == oldLayout)
            #expect(subject.state.layout.moveCode == "a1")
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
            #expect(animator.oldLayout == oldLayout)
            #expect(animator.newLayout == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("tapped: if firstTapLocation is column, if second location is column, move maximum movable")
    func tapSecondColumnFromColumn() async {
        subject.state.gameProgress = .inProgress
        do {
            // can't put a heart on a heart
            subject.state.layout.columns[0].cards = [Card(rank: .six, suit: .hearts)]
            subject.state.layout.columns[1].cards = [Card(rank: .five, suit: .hearts)]
            subject.state.layout.moveCode = "heyho"
            subject.state.firstTapLocation = Location(category: .column, index: 1)
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            subject.state.autoplay = false
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(subject.state.layout.moveCode == "heyho")
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled.isEmpty)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        stopwatch.methodsCalled = []
        do {
            subject.state.layout.columns[0].cards = [Card(rank: .six, suit: .hearts)]
            subject.state.layout.columns[1].cards = [
                Card(rank: .six, suit: .diamonds),
                Card(rank: .five, suit: .clubs),
                Card(rank: .four, suit: .diamonds)
            ]
            subject.state.layout.moveCode = "heyho"
            subject.state.firstTapLocation = Location(category: .column, index: 1)
            subject.state.autoplay = false
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.layout.columns[1].cards == [Card(rank: .six, suit: .diamonds)])
            #expect(subject.state.layout.columns[0].cards == [
                Card(rank: .six, suit: .hearts),
                Card(rank: .five, suit: .clubs),
                Card(rank: .four, suit: .diamonds),
            ])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.last == oldLayout)
            #expect(subject.state.layout.moveCode == "21")
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
            #expect(animator.oldLayout == oldLayout)
            #expect(animator.newLayout == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("tapped: if firstTapLocation is column, if second location is column, if move would move all, do nothing")
    func tapSecondColumnFromColumnAll() async {
        subject.state.gameProgress = .inProgress
        subject.state.layout.columns[0].cards = []
        subject.state.layout.columns[1].cards = [
            Card(rank: .six, suit: .diamonds),
            Card(rank: .five, suit: .clubs),
            Card(rank: .four, suit: .diamonds)
        ]
        subject.state.layout.moveCode = "heyho"
        subject.state.firstTapLocation = Location(category: .column, index: 1)
        let oldLayout = subject.state.layout
        subject.state.autoplay = false
        subject.state.undoStack = [Layout()]
        subject.state.redoStack = [Layout()]
        await subject.receive(.tapped(Location(category: .column, index: 0)))
        #expect(subject.state.layout == oldLayout)
        #expect(subject.state.undoStack == [Layout()])
        #expect(subject.state.redoStack == [Layout()])
        #expect(subject.state.layout.moveCode == "heyho")
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.enablements == subject.state.baseEnablements)
        #expect(presenter.statesPresented == [subject.state])
        #expect(animator.methodsCalled.isEmpty)
        #expect(stopwatch.methodsCalled == ["advance()"])
    }

    @Test("tapped: if autoplay is on, second tap is followed by a round of autoplay")
    func autoplayAfterSecondTap() async {
        subject.state.gameProgress = .inProgress
        do {
            subject.state.layout.columns[0].cards = [Card(rank: .six, suit: .hearts)]
            subject.state.layout.columns[1].cards = [
                Card(rank: .six, suit: .diamonds),
                Card(rank: .five, suit: .clubs),
                Card(rank: .four, suit: .diamonds)
            ]
            subject.state.layout.columns[2].cards = [Card(rank: .two, suit: .spades)]
            subject.state.layout.freeCells[0].cards = [Card(rank: .three, suit: .spades)]
            subject.state.layout.foundations[0].cards = [Card(rank: .ace, suit: .spades)]
            subject.state.layout.moveCode = "heyho"
            subject.state.firstTapLocation = Location(category: .column, index: 1)
            subject.state.autoplay = false // *
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.layout.columns[1].cards == [Card(rank: .six, suit: .diamonds)])
            #expect(subject.state.layout.columns[0].cards == [
                Card(rank: .six, suit: .hearts),
                Card(rank: .five, suit: .clubs),
                Card(rank: .four, suit: .diamonds),
            ])
            #expect(subject.state.layout.columns[2].cards == [Card(rank: .two, suit: .spades)])
            #expect(subject.state.layout.freeCells[0].cards == [Card(rank: .three, suit: .spades)])
            #expect(subject.state.layout.foundations[0].cards == [Card(rank: .ace, suit: .spades)])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.last == oldLayout)
            #expect(subject.state.layout.moveCode == "21")
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
            #expect(animator.oldLayout == oldLayout)
            #expect(animator.newLayout == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        stopwatch.methodsCalled = []
        animator.methodsCalled = []
        animator.oldLayouts = []
        animator.newLayouts = []
        do {
            subject.state.layout.columns[0].cards = [Card(rank: .six, suit: .hearts)]
            subject.state.layout.columns[1].cards = [
                Card(rank: .six, suit: .diamonds),
                Card(rank: .five, suit: .clubs),
                Card(rank: .four, suit: .diamonds)
            ]
            subject.state.layout.columns[2].cards = [Card(rank: .two, suit: .spades)] // *
            subject.state.layout.freeCells[0].cards = [Card(rank: .three, suit: .spades)] // *
            subject.state.layout.foundations[0].cards = [Card(rank: .ace, suit: .spades)]
            subject.state.layout.foundations[1].cards = [Card(rank: .ace, suit: .hearts)]
            subject.state.layout.foundations[3].cards = [Card(rank: .ace, suit: .diamonds)]
            subject.state.layout.moveCode = "heyho"
            subject.state.firstTapLocation = Location(category: .column, index: 1)
            subject.state.autoplay = true // *
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.layout.columns[1].cards == [Card(rank: .six, suit: .diamonds)])
            #expect(subject.state.layout.columns[0].cards == [
                Card(rank: .six, suit: .hearts),
                Card(rank: .five, suit: .clubs),
                Card(rank: .four, suit: .diamonds),
            ])
            #expect(subject.state.layout.columns[2].cards == [])
            #expect(subject.state.layout.freeCells[0].cards == [])
            #expect(subject.state.layout.foundations[0].cards == [
                Card(rank: .ace, suit: .spades),
                Card(rank: .two, suit: .spades),
                Card(rank: .three, suit: .spades),
            ])
            #expect(subject.state.layout.foundations[1].cards == [Card(rank: .ace, suit: .hearts)])
            #expect(subject.state.layout.foundations[3].cards == [Card(rank: .ace, suit: .diamonds)])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.first == oldLayout)
            #expect(subject.state.undoStack.last?.foundations[0].cards == [Card(rank: .ace, suit: .spades)])
            #expect(subject.state.undoStack.last?.moveCode == "21")
            #expect(subject.state.layout.moveCode == nil)
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented.count == 2)
            #expect(presenter.statesPresented.last == subject.state)
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)", "animate(oldLayout:newLayout:speed:)"])
            let middleLayout = subject.state.undoStack.last!
            #expect(animator.oldLayouts[0] == oldLayout)
            #expect(animator.newLayouts[0] == middleLayout)
            #expect(animator.oldLayouts[1] == middleLayout)
            #expect(animator.newLayouts[1] == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("receive undo: if undo stack not empty, move one undo layout to layout and layout to redo")
    func undo() async {
        subject.state.gameProgress = .inProgress
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            let oldState = subject.state
            await subject.receive(.undo)
            #expect(subject.state == oldState)
            #expect(subject.state.redoStack.isEmpty)
            #expect(presenter.statesPresented.isEmpty)
            #expect(animator.methodsCalled.isEmpty)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        stopwatch.methodsCalled = []
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            var undoLayout1 = Layout()
            undoLayout1.columns[1].cards = [Card(rank: .queen, suit: .hearts)]
            var undoLayout2 = Layout()
            undoLayout2.columns[2].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.undoStack.append(undoLayout2)
            subject.state.undoStack.append(undoLayout1)
            let oldLayout = subject.state.layout
            await subject.receive(.undo)
            #expect(subject.state.redoStack.first?.columns[0].cards == [Card(rank: .queen, suit: .hearts)])
            #expect(subject.state.layout.columns[0].cards == [])
            #expect(subject.state.layout.columns[1].cards == [Card(rank: .queen, suit: .hearts)])
            #expect(subject.state.undoStack.last?.columns[0].cards == [])
            #expect(subject.state.undoStack.last?.columns[1].cards == [])
            #expect(subject.state.undoStack.last?.columns[2].cards == [Card(rank: .queen, suit: .hearts)])
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
            #expect(animator.oldLayout == oldLayout)
            #expect(animator.newLayout == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("receive undoAll: if undo stack not empty, moves undo layouts to redo, last one to layout")
    func undoAll() async {
        subject.state.gameProgress = .inProgress
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            let oldState = subject.state
            await subject.receive(.undoAll)
            #expect(subject.state == oldState)
            #expect(subject.state.redoStack.isEmpty)
            #expect(presenter.statesPresented.isEmpty)
            #expect(animator.methodsCalled.isEmpty)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
        stopwatch.methodsCalled = []
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            var undoLayout1 = Layout()
            undoLayout1.columns[1].cards = [Card(rank: .queen, suit: .hearts)]
            var undoLayout2 = Layout()
            undoLayout2.columns[2].cards = [Card(rank: .queen, suit: .hearts)]
            subject.state.undoStack.append(undoLayout2)
            subject.state.undoStack.append(undoLayout1)
            let oldLayout = subject.state.layout
            await subject.receive(.undoAll)
            #expect(subject.state.redoStack.first?.columns[0].cards == [Card(rank: .queen, suit: .hearts)])
            #expect(subject.state.redoStack.last?.columns[0].cards == [])
            #expect(subject.state.redoStack.last?.columns[1].cards == [Card(rank: .queen, suit: .hearts)])
            #expect(subject.state.layout.columns[0].cards == [])
            #expect(subject.state.layout.columns[1].cards == [])
            #expect(subject.state.layout.columns[2].cards == [Card(rank: .queen, suit: .hearts)])
            #expect(subject.state.undoStack == [])
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
            #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
            #expect(animator.oldLayout == oldLayout)
            #expect(animator.newLayout == subject.state.layout)
            #expect(animator.speed == subject.state.animationSpeed)
            #expect(stopwatch.methodsCalled == ["advance()"])
        }
    }

    @Test("receive autoplay or tapped: if the layout is empty of freecell / column cards, declares the game over")
    func receiveWhenGameOver() async {
        stopwatch.state = .running
        subject.state.gameProgress = .inProgress
        do {
            await subject.receive(.autoplay)
            #expect(subject.state.gameProgress == .gameOver)
            #expect(stopwatch.methodsCalled == ["stop()"])
            await #while(presenter.thingsReceived.isEmpty)
            #expect(presenter.thingsReceived.last == .confetti)
        }
        presenter.thingsReceived = []
        stopwatch.methodsCalled = []
        stopwatch.state = .running
        subject.state.gameProgress = .inProgress
        do {
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.gameProgress == .gameOver)
            #expect(stopwatch.methodsCalled == ["stop()"])
            await #while(presenter.thingsReceived.isEmpty)
            #expect(presenter.thingsReceived.last == .confetti)
        }
    }

    @Test("receive autoplay or tapped: if declares the game over, saves the won game stat")
    func receiveWhenGameOverSaveGame() async {
        stopwatch.state = .running
        subject.state.gameProgress = .inProgress
        var layout = Layout()
        layout.moveCode = "heyho"
        layout.columns[0].cards = [Card(rank: .jack, suit: .hearts)]
        subject.state.undoStack = [layout, Layout()]
        stopwatch.elapsedTime = 200
        let expected = Stat(
            dateFinished: Date.distantPast,
            won: true,
            initialLayout: layout,
            movesCount: 1,
            timeTaken: 200,
            codes: ["heyho"]
        )
        do {
            await subject.receive(.autoplay)
            await #while(stats.methodsCalled.isEmpty)
            #expect(stats.methodsCalled == ["saveStat(_:)"])
            #expect(stats.stat == expected)
        }
        stats.methodsCalled = []
        stats.stat = nil
        stopwatch.state = .running
        subject.state.gameProgress = .inProgress
        do {
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            await #while(stats.methodsCalled.isEmpty)
            #expect(stats.methodsCalled == ["saveStat(_:)"])
            #expect(stats.stat == expected)
        }
    }

    @Test("receive autoplay or tapped: if the layout is empty, but game not in progress, no confetti, no save")
    func receiveWhenGameOverGameNotInProgress() async {
        stopwatch.state = .running
        subject.state.gameProgress = .gameOver
        do {
            await subject.receive(.autoplay)
            #expect(subject.state.gameProgress == .gameOver)
            #expect(stopwatch.methodsCalled == ["stop()"])
            #expect(!presenter.thingsReceived.contains(.confetti))
            #expect(stats.methodsCalled.isEmpty)
        }
        presenter.thingsReceived = []
        stopwatch.methodsCalled = []
        stopwatch.state = .running
        subject.state.gameProgress = .gameOver
        do {
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(subject.state.gameProgress == .gameOver)
            #expect(stopwatch.methodsCalled == ["stop()"])
            #expect(!presenter.thingsReceived.contains(.confetti))
            #expect(stats.methodsCalled.isEmpty)
        }
    }

    @Test("every `receive`, if game waiting for first move and stopwatch stopped, start")
    func receiveWhenGameOverGameWaitingForFirstMoveStopped() async {
        stopwatch.state = .stopped
        subject.state.gameProgress = .dealtWaitingForFirstMove
        subject.state.layout.columns[7].cards = [Card(rank: .six, suit: .clubs)]
        do {
            await subject.receive(.autoplay)
            #expect(stopwatch.methodsCalled == ["start()"])
            #expect(subject.state.gameProgress == .inProgress)
        }
        stopwatch.state = .stopped
        subject.state.gameProgress = .dealtWaitingForFirstMove
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.hint)
            #expect(stopwatch.methodsCalled == ["start()"])
            #expect(subject.state.gameProgress == .inProgress)
        }
        stopwatch.state = .stopped
        subject.state.gameProgress = .dealtWaitingForFirstMove
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.longPressEnded)
            #expect(stopwatch.methodsCalled == ["start()"])
            #expect(subject.state.gameProgress == .inProgress)
        }
        stopwatch.state = .stopped
        subject.state.gameProgress = .dealtWaitingForFirstMove
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.redo)
            #expect(stopwatch.methodsCalled == ["start()"])
            #expect(subject.state.gameProgress == .inProgress)
        }
        stopwatch.state = .stopped
        subject.state.gameProgress = .dealtWaitingForFirstMove
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.redoAll)
            #expect(stopwatch.methodsCalled == ["start()"])
            #expect(subject.state.gameProgress == .inProgress)
        }
        stopwatch.state = .stopped
        subject.state.gameProgress = .dealtWaitingForFirstMove
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.tapBackground)
            #expect(stopwatch.methodsCalled == ["start()"])
            #expect(subject.state.gameProgress == .inProgress)
        }
        stopwatch.state = .stopped
        subject.state.gameProgress = .dealtWaitingForFirstMove
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(stopwatch.methodsCalled == ["start()"])
            #expect(subject.state.gameProgress == .inProgress)
        }
        stopwatch.state = .stopped
        subject.state.gameProgress = .dealtWaitingForFirstMove
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.undo)
            #expect(stopwatch.methodsCalled == ["start()"])
            #expect(subject.state.gameProgress == .inProgress)
        }
        stopwatch.state = .stopped
        subject.state.gameProgress = .dealtWaitingForFirstMove
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.undoAll)
            #expect(stopwatch.methodsCalled == ["start()"])
            #expect(subject.state.gameProgress == .inProgress)
        }
    }

    @Test("every `receive`, if game in progress and stopwatch stopped, start")
    func receiveWhenGameOverGameInProgressStopped() async {
        stopwatch.state = .stopped
        subject.state.gameProgress = .inProgress
        subject.state.layout.columns[7].cards = [Card(rank: .six, suit: .clubs)]
        do {
            await subject.receive(.autoplay)
            #expect(stopwatch.methodsCalled == ["start()"])
        }
        stopwatch.state = .stopped
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.hint)
            #expect(stopwatch.methodsCalled == ["start()"])
        }
        stopwatch.state = .stopped
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.longPressEnded)
            #expect(stopwatch.methodsCalled == ["start()"])
        }
        stopwatch.state = .stopped
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.redo)
            #expect(stopwatch.methodsCalled == ["start()"])
        }
        stopwatch.state = .stopped
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.redoAll)
            #expect(stopwatch.methodsCalled == ["start()"])
        }
        stopwatch.state = .stopped
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.tapBackground)
            #expect(stopwatch.methodsCalled == ["start()"])
        }
        stopwatch.state = .stopped
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(stopwatch.methodsCalled == ["start()"])
        }
        stopwatch.state = .stopped
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.undo)
            #expect(stopwatch.methodsCalled == ["start()"])
        }
        stopwatch.state = .stopped
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.undoAll)
            #expect(stopwatch.methodsCalled == ["start()"])
        }
    }

    @Test("every `receive`, if game in progress and stopwatch paused, resume")
    func receiveWhenGameOverGameInProgressPaused() async {
        stopwatch.state = .paused
        subject.state.gameProgress = .inProgress
        subject.state.layout.columns[7].cards = [Card(rank: .six, suit: .clubs)]
        do {
            await subject.receive(.autoplay)
            #expect(stopwatch.methodsCalled == ["resumeIfPaused()"])
        }
        stopwatch.state = .paused
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.hint)
            #expect(stopwatch.methodsCalled == ["resumeIfPaused()"])
        }
        stopwatch.state = .paused
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.longPressEnded)
            #expect(stopwatch.methodsCalled == ["resumeIfPaused()"])
        }
        stopwatch.state = .paused
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.redo)
            #expect(stopwatch.methodsCalled == ["resumeIfPaused()"])
        }
        stopwatch.state = .paused
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.redoAll)
            #expect(stopwatch.methodsCalled == ["resumeIfPaused()"])
        }
        stopwatch.state = .paused
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.tapBackground)
            #expect(stopwatch.methodsCalled == ["resumeIfPaused()"])
        }
        stopwatch.state = .paused
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.tapped(Location(category: .column, index: 0)))
            #expect(stopwatch.methodsCalled == ["resumeIfPaused()"])
        }
        stopwatch.state = .paused
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.undo)
            #expect(stopwatch.methodsCalled == ["resumeIfPaused()"])
        }
        stopwatch.state = .paused
        stopwatch.methodsCalled = []
        do {
            await subject.receive(.undoAll)
            #expect(stopwatch.methodsCalled == ["resumeIfPaused()"])
        }
    }

    @Test("stopwatchDidUpdate: passes updateStopwatch to presenter")
    func stopwatchDidUpdate() async {
        await subject.stopwatchDidUpdate(32)
        #expect(presenter.thingsReceived == [.updateStopwatch(32)])
    }

    @Test("resumeStat: calls coordinator popToGame")
    func resumeStatPop() async {
        await subject.resume(stat: Stat(dateFinished: Date.now, won: false, initialLayout: Layout(), movesCount: 3, timeTaken: 200))
        #expect(coordinator.methodsCalled == ["popToGame()"])
        print("test")
    }

    @Test("resumeStat: exactly like deal if game is over")
    func resumeStat() async {
        var layout = Layout()
        layout.foundations[0].cards = [Card(rank: .jack, suit: .hearts)]
        subject.state.layout = layout
        subject.state.gameProgress = .gameOver
        subject.state.firstTapLocation = Location(category: .column, index: 0)
        subject.state.undoStack = [Layout(), Layout()]
        subject.state.redoStack = [Layout(), Layout()]
        subject.state.layout.moveCode = "yoho"
        var statLayout = Layout()
        statLayout.columns[0].cards = [Card(rank: .jack, suit: .hearts)]
        await subject.resume(stat: Stat(dateFinished: Date.now, won: false, initialLayout: statLayout, movesCount: 3, timeTaken: 200))
        #expect(subject.state.layout == statLayout)
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.enablements == subject.state.baseEnablements)
        #expect(presenter.statesPresented == [subject.state])
        #expect(subject.state.undoStack.isEmpty)
        #expect(subject.state.redoStack.isEmpty)
        #expect(subject.state.layout.moveCode == nil)
        #expect(subject.state.gameProgress == .dealtWaitingForFirstMove)
        #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
        #expect(animator.oldLayout == Layout()) // animated as if dealing
        #expect(animator.newLayout == statLayout)
        #expect(animator.speed == subject.state.animationSpeed)
        #expect(stopwatch.methodsCalled == ["reset(to:)"])
        #expect(stopwatch.resetTimeInterval == 200)
        try? await Task.sleep(for: .seconds(0.1))
        #expect(stats.methodsCalled.isEmpty)
    }

    @Test("resumeStat: if game progress is not gameOver, saves current game as lost, animates from it")
    func resumeStatGameNotOver() async {
        var oldLayout = Layout()
        oldLayout.foundations[0].cards = [Card(rank: .jack, suit: .hearts)]
        subject.state.layout = oldLayout
        subject.state.gameProgress = .inProgress // *
        subject.state.firstTapLocation = Location(category: .column, index: 0)
        subject.state.undoStack = [oldLayout, Layout()] // teehee
        subject.state.redoStack = [Layout(), Layout()]
        subject.state.layout.moveCode = "yoho"
        var statLayout = Layout()
        statLayout.columns[0].cards = [Card(rank: .jack, suit: .hearts)]
        await subject.resume(stat: Stat(dateFinished: Date.now, won: false, initialLayout: statLayout, movesCount: 3, timeTaken: 200))
        #expect(subject.state.layout == statLayout)
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.enablements == subject.state.baseEnablements)
        #expect(presenter.statesPresented == [subject.state])
        #expect(subject.state.undoStack.isEmpty)
        #expect(subject.state.redoStack.isEmpty)
        #expect(subject.state.layout.moveCode == nil)
        #expect(subject.state.gameProgress == .dealtWaitingForFirstMove)
        #expect(animator.methodsCalled == ["animate(oldLayout:newLayout:speed:)"])
        #expect(animator.oldLayout == oldLayout) // animated from existing old game
        #expect(animator.newLayout == statLayout)
        #expect(animator.speed == subject.state.animationSpeed)
        #expect(stopwatch.methodsCalled == ["reset(to:)"])
        #expect(stopwatch.resetTimeInterval == 200)
        await #while(stats.methodsCalled.isEmpty)
        #expect(stats.methodsCalled == ["saveStat(_:)"])
        #expect(stats.stat == Stat(
            dateFinished: Date.distantPast,
            won: false,
            initialLayout: oldLayout,
            movesCount: 1,
            timeTaken: 0,
            codes: ["yoho"]
        ))
    }
}
