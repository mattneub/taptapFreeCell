@testable import FreeCell
import Testing
import Foundation

struct GameProcessorTests {
    let subject = GameProcessor()
    let presenter = MockReceiverPresenter<GameEffect, GameState>()

    init() {
        subject.presenter = presenter
    }

    @Test("receive autoplay: plays all can-go non-needed from columns and freecells to foundations, updates undo/redo")
    func autoplay() async {
        var layout = Layout()
        layout.foundations[0].cards = [
            .init(rank: .ace, suit: .spades),
            .init(rank: .two, suit: .spades)
        ]
        layout.columns[0].cards = [
            .init(rank: .two, suit: .clubs),
            .init(rank: .ace, suit: .clubs)
        ]
        layout.columns[1].cards = [
            .init(rank: .three, suit: .spades),
        ]
        layout.freeCells[0].cards = [.init(rank: .two, suit: .hearts)]
        layout.freeCells[1].cards = [.init(rank: .ace, suit: .hearts)]
        subject.state.layout = layout
        subject.state.firstTapLocation = .init(category: .column, index: 0)
        subject.state.redoStack = [Layout()]
        let oldLayout = layout
        await subject.receive(.autoplay)
        #expect(subject.state.layout.foundations[0].cards == [
            .init(rank: .ace, suit: .spades),
            .init(rank: .two, suit: .spades)
        ]) // did not autoplay the three, it might be needed
        #expect(subject.state.layout.foundations[1].cards == [
            .init(rank: .ace, suit: .hearts),
            .init(rank: .two, suit: .hearts)
        ]) // from the free cells
        #expect(subject.state.layout.foundations[2].cards == [
            .init(rank: .ace, suit: .clubs),
            .init(rank: .two, suit: .clubs)

        ]) // autoplayed the ace, then the two in another round
        #expect(subject.state.layout.columns[0].isEmpty)
        #expect(subject.state.layout.columns[1].cards == [.init(rank: .three, suit: .spades)])
        #expect(subject.state.layout.freeCells.allSatisfy { $0.card == nil })
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.enablements == subject.state.baseEnablements)
        #expect(subject.state.undoStack.last == oldLayout)
        #expect(subject.state.redoStack.isEmpty)
    }

    @Test("receive deal: creates a new full-deal layout, puts it in the state, and presents it, empties undo/redo")
    func deal() async {
        subject.state.firstTapLocation = .init(category: .column, index: 0)
        subject.state.undoStack = [Layout(), Layout()]
        subject.state.redoStack = [Layout(), Layout()]
        #expect(subject.state.layout == Layout())
        await subject.receive(.deal)
        let tableau = subject.state.layout.shlomiTableauDescription.replacing(/[\s\n]/, with: "")
        #expect(tableau.count == 104) // fifty two cards
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.enablements == subject.state.baseEnablements)
        #expect(presenter.statesPresented == [subject.state])
        #expect(subject.state.undoStack.isEmpty)
        #expect(subject.state.redoStack.isEmpty)
    }

    @Test("receive hint: enables freecells and columns that can move nontrivially")
    func hint() async {
        subject.state.layout.foundations[0].cards = [.init(rank: .six, suit: .spades)]
        subject.state.layout.freeCells[0].cards = [.init(rank: .seven, suit: .spades)]
        subject.state.layout.freeCells[1].cards = [.init(rank: .two, suit: .clubs)]
        subject.state.layout.freeCells[2].cards = [.init(rank: .king, suit: .hearts)]
        subject.state.layout.columns[0].cards = [.init(rank: .eight, suit: .hearts), .init(rank: .seven, suit: .spades)]
        subject.state.layout.columns[1].cards = [.init(rank: .six, suit: .hearts)]
        subject.state.layout.columns[2].cards = [.init(rank: .three, suit: .hearts)]
        subject.state.layout.columns[3].cards = [.init(rank: .five, suit: .diamonds), .init(rank: .four, suit: .spades)]
        var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
        expected[.init(category: .freeCell, index: 0)] = .enabled // seven can go on six in foundations
        expected[.init(category: .freeCell, index: 1)] = .enabled // two can go on three in column 2
        expected[.init(category: .column, index: 0)] = .enabled // seven can go on six in foundations
        expected[.init(category: .column, index: 1)] = .enabled // six can go on seven in column 0
        expected[.init(category: .column, index: 2)] = .enabled // three can go on four in column 3
        await subject.receive(.hint)
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.enablements == expected)
        #expect(presenter.statesPresented == [subject.state])
    }

    @Test("receive redo: if redo stack not empty, move one redo layout to layout and layout to undo")
    func redo() async {
        do {
            subject.state.firstTapLocation = .init(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            let oldState = subject.state
            await subject.receive(.redo)
            #expect(subject.state == oldState)
            #expect(subject.state.undoStack.isEmpty)
            #expect(presenter.statesPresented.isEmpty)
        }
        do {
            subject.state.firstTapLocation = .init(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            var redoLayout1 = Layout()
            redoLayout1.columns[1].cards = [.init(rank: .queen, suit: .hearts)]
            var redoLayout2 = Layout()
            redoLayout2.columns[2].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.redoStack.append(redoLayout2)
            subject.state.redoStack.append(redoLayout1)
            await subject.receive(.redo)
            #expect(subject.state.undoStack.first?.columns[0].cards == [.init(rank: .queen, suit: .hearts)])
            #expect(subject.state.layout.columns[0].cards == [])
            #expect(subject.state.layout.columns[1].cards == [.init(rank: .queen, suit: .hearts)])
            #expect(subject.state.redoStack.last?.columns[0].cards == [])
            #expect(subject.state.redoStack.last?.columns[1].cards == [])
            #expect(subject.state.redoStack.last?.columns[2].cards == [.init(rank: .queen, suit: .hearts)])
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
        }
    }

    @Test("receive redoAll: if redo stack not empty, moves redo layouts to undo, last one to layout")
    func redoAll() async {
        do {
            subject.state.firstTapLocation = .init(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            let oldState = subject.state
            await subject.receive(.redoAll)
            #expect(subject.state == oldState)
            #expect(subject.state.undoStack.isEmpty)
            #expect(presenter.statesPresented.isEmpty)
        }
        do {
            subject.state.firstTapLocation = .init(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            var redoLayout1 = Layout()
            redoLayout1.columns[1].cards = [.init(rank: .queen, suit: .hearts)]
            var redoLayout2 = Layout()
            redoLayout2.columns[2].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.redoStack.append(redoLayout2)
            subject.state.redoStack.append(redoLayout1)
            await subject.receive(.redoAll)
            #expect(subject.state.undoStack.first?.columns[0].cards == [.init(rank: .queen, suit: .hearts)])
            #expect(subject.state.undoStack.last?.columns[0].cards == [])
            #expect(subject.state.undoStack.last?.columns[1].cards == [.init(rank: .queen, suit: .hearts)])
            #expect(subject.state.layout.columns[0].cards == [])
            #expect(subject.state.layout.columns[1].cards == [])
            #expect(subject.state.layout.columns[2].cards == [.init(rank: .queen, suit: .hearts)])
            #expect(subject.state.redoStack == [])
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
        }
    }

    @Test("receive tapBackground: erases existing first tap, returns to neutrality")
    func tapBackground() async {
        subject.state.firstTapLocation = .init(category: .column, index: 0)
        await subject.receive(.tapBackground)
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.enablements == subject.state.baseEnablements)
        #expect(presenter.statesPresented == [subject.state])
    }

    @Test("tapped: if firstTapLocation is nil, tapped location becomes firstTapLocation if not empty source, not foundation")
    func tappedFirst() async {
        do {
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        do {
            subject.state.layout.foundations[0].cards = [.init(rank: .ace, suit: .spades)]
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .foundation, index: 0)))
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        do {
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.unambiguousMove = false
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.firstTapLocation == Location(category: .column, index: 0))
            #expect(subject.state.enablements != subject.state.baseEnablements)
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(presenter.statesPresented == [subject.state])
        }
    }

    @Test("tapped: if firstTapLocation is nil, if card can be autoplayed, it is, followed by autoplay if enabled, undo/redo")
    func tappedFirstCanAutoplay() async {
        do {
            subject.state.layout.columns[0].cards = [
                .init(rank: .two, suit: .clubs),
                .init(rank: .ace, suit: .clubs),
            ]
            subject.state.autoplay = false // we will play just the ace and stop
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.layout.foundation(for: .clubs).cards == [.init(rank: .ace, suit: .clubs)])
            #expect(subject.state.layout.columns[0].cards == [.init(rank: .two, suit: .clubs)])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.last?.columns[0].cards == [
                .init(rank: .two, suit: .clubs),
                .init(rank: .ace, suit: .clubs),
            ])
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        do {
            subject.state.layout.columns[0].cards = [
                .init(rank: .two, suit: .clubs),
                .init(rank: .ace, suit: .clubs),
            ]
            subject.state.autoplay = true // we will play and then autoplay
            subject.state.redoStack = [Layout]()
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.layout.foundation(for: .clubs).cards == [
                .init(rank: .ace, suit: .clubs),
                .init(rank: .two, suit: .clubs)
            ])
            #expect(subject.state.layout.columns[0].cards == [])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.first?.columns[0].cards == [
                .init(rank: .two, suit: .clubs),
                .init(rank: .ace, suit: .clubs),
            ])
            #expect(subject.state.undoStack.last?.columns[0].cards == [
                .init(rank: .two, suit: .clubs),
            ])
            #expect(subject.state.undoStack.last?.foundation(for: .clubs).cards == [
                .init(rank: .ace, suit: .clubs)
            ])
            #expect(presenter.statesPresented.last == subject.state)
        }
    }

    @Test("tapped: if valid first tap, enablements are set or not depending on showDestinations")
    func showDestinations() async {
        do {
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .clubs)]
            subject.state.showDestinations = false
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.firstTapLocation == .init(category: .column, index: 0))
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        do {
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .clubs)]
            subject.state.showDestinations = true // default
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.enablements != subject.state.baseEnablements)
            #expect(subject.state.firstTapLocation == .init(category: .column, index: 0))
            #expect(presenter.statesPresented == [subject.state])
        }
    }

    @Test("tapped: first tap enablements are right for column tapped")
    func enablementsColumn() async {
        do {
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .clubs)]
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            expected[.init(category: .column, index: 1)] = .enabled
            (0..<4).forEach { expected[.init(category: .freeCell, index: $0)] = .enabled }
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == .init(category: .column, index: 0))
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        do {
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .clubs)]
            subject.state.layout.foundations[1].cards = [.init(rank: .jack, suit: .hearts)]
            subject.state.layout.freeCells[0].cards = [.init(rank: .two, suit: .clubs)]
            subject.state.layout.freeCells[1].cards = [.init(rank: .two, suit: .clubs)]
            subject.state.layout.freeCells[2].cards = [.init(rank: .two, suit: .clubs)]
            subject.state.layout.freeCells[3].cards = [.init(rank: .two, suit: .clubs)]
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            expected[.init(category: .column, index: 1)] = .enabled
            (0..<4).forEach { expected[.init(category: .foundation, index: $0)] = .enabled }
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == .init(category: .column, index: 0))
            #expect(presenter.statesPresented == [subject.state])
        }
    }

    @Test("tapped: first tap enablements are right for freeCell tapped")
    func enablementsFreeCell() async {
        do {
            subject.state.layout.freeCells[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .clubs)]
            subject.state.layout.columns[2].cards = [.init(rank: .king, suit: .diamonds)]
            await subject.receive(.tapped(.init(category: .freeCell, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            (0..<8).forEach { expected[.init(category: .column, index: $0)] = .enabled }
            expected[.init(category: .column, index: 2)] = .disabled
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == .init(category: .freeCell, index: 0))
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        do {
            subject.state.layout.freeCells[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .clubs)]
            subject.state.layout.columns[2].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.foundations[1].cards = [.init(rank: .jack, suit: .hearts)]
            await subject.receive(.tapped(.init(category: .freeCell, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            (0..<4).forEach { expected[.init(category: .foundation, index: $0)] = .enabled }
            (0..<8).forEach { expected[.init(category: .column, index: $0)] = .enabled }
            expected[.init(category: .column, index: 2)] = .disabled
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == .init(category: .freeCell, index: 0))
            #expect(presenter.statesPresented == [subject.state])
        }
    }

    @Test("tapped: if firstTapLocation is nil, if state unambiguousMove is true, if no unambiguous move, acts normally")
    func tapFirstUnambiguousNone() async {
        do {
            subject.state.layout.freeCells[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .clubs)]
            subject.state.layout.columns[2].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.unambiguousMove = true
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .freeCell, index: 0)))
            #expect(subject.state.layout == oldLayout)
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            (0..<8).forEach { expected[.init(category: .column, index: $0)] = .enabled }
            expected[.init(category: .column, index: 2)] = .disabled
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == .init(category: .freeCell, index: 0))
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        do {
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .clubs)]
            subject.state.unambiguousMove = true
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.firstTapLocation == .init(category: .column, index: 0))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            expected[.init(category: .column, index: 1)] = .enabled
            (0..<4).forEach { expected[.init(category: .freeCell, index: $0)] = .enabled }
            #expect(subject.state.enablements == expected)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(presenter.statesPresented == [subject.state])
        }
    }

    @Test("tapped: if firstTapLocation is nil, if state unambiguousMove is true, if unambiguous move, makes it, undo/redo")
    func tapFirstUnambiguousYesFreeCell() async {
        do {
            subject.state.layout.foundations[1].cards = [.init(rank: .jack, suit: .hearts)]
            subject.state.layout.freeCells[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[2].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [.init(rank: .ace, suit: .diamonds)]
            subject.state.layout.columns[0].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.unambiguousMove = false
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .freeCell, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            expected[.init(category: .foundation, index: 0)] = .enabled
            expected[.init(category: .foundation, index: 1)] = .enabled
            expected[.init(category: .foundation, index: 2)] = .enabled
            expected[.init(category: .foundation, index: 3)] = .enabled
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == .init(category: .freeCell, index: 0))
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        do {
            subject.state.layout.foundations[1].cards = [.init(rank: .jack, suit: .hearts)]
            subject.state.layout.freeCells[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[2].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [.init(rank: .ace, suit: .diamonds)]
            subject.state.layout.columns[0].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.unambiguousMove = true // *
            let oldLayout = subject.state.layout
            await subject.receive(.tapped(.init(category: .freeCell, index: 0)))
            #expect(subject.state.layout.foundations[1].cards == [
                .init(rank: .jack, suit: .hearts),
                .init(rank: .queen, suit: .hearts),
            ])
            #expect(subject.state.layout.freeCells[0].isEmpty)
            #expect(subject.state.layout.columns[7].isEmpty) // because there was a round of autoplay
            #expect(subject.state.layout.foundations[3].cards == [.init(rank: .ace, suit: .diamonds)])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.first == oldLayout)
            #expect(subject.state.undoStack.last?.columns[7].cards == [.init(rank: .ace, suit: .diamonds)])
            // because that change happened in the round of autoplay
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.firstTapLocation == nil)
            #expect(presenter.statesPresented.last == subject.state)
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        do {
            subject.state.layout.freeCells[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .clubs)]
            subject.state.layout.columns[2].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [.init(rank: .ace, suit: .diamonds)]
            subject.state.layout.columns[0].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.unambiguousMove = false
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            let oldLayout = subject.state.layout
            await subject.receive(.tapped(.init(category: .freeCell, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            expected[.init(category: .column, index: 1)] = .enabled
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == .init(category: .freeCell, index: 0))
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        do {
            subject.state.layout.freeCells[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .clubs)]
            subject.state.layout.columns[2].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [.init(rank: .ace, suit: .diamonds)]
            subject.state.layout.columns[0].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.unambiguousMove = true // *
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .freeCell, index: 0)))
            #expect(subject.state.layout.freeCells[0].isEmpty)
            #expect(subject.state.layout.columns[1].cards == [
                .init(rank: .king, suit: .clubs),
                .init(rank: .queen, suit: .hearts),
            ])
            #expect(subject.state.layout.columns[7].isEmpty)
            #expect(subject.state.layout.foundations[3].cards == [.init(rank: .ace, suit: .diamonds)])
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.first == oldLayout)
            #expect(subject.state.undoStack.last?.columns[7].cards == [.init(rank: .ace, suit: .diamonds)])
            #expect(presenter.statesPresented.last == subject.state)
        }
    }

    // same idea as preceding except that the tap is a column instead of a freecell
    @Test("tapped: if firstTapLocation is nil, if state unambiguousMove is true, if unambiguous move, makes it, undo/redo")
    func tapFirstUnambiguousYesColumn() async {
        do {
            subject.state.layout.foundations[1].cards = [.init(rank: .jack, suit: .hearts)]
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[2].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [.init(rank: .ace, suit: .diamonds)]
            subject.state.layout.freeCells[0].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[1].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[2].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[3].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.unambiguousMove = false
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            expected[.init(category: .foundation, index: 0)] = .enabled
            expected[.init(category: .foundation, index: 1)] = .enabled
            expected[.init(category: .foundation, index: 2)] = .enabled
            expected[.init(category: .foundation, index: 3)] = .enabled
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == .init(category: .column, index: 0))
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        do {
            subject.state.layout.foundations[1].cards = [.init(rank: .jack, suit: .hearts)]
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[2].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [.init(rank: .ace, suit: .diamonds)]
            subject.state.layout.freeCells[0].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[1].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[2].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[3].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.unambiguousMove = true
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.layout.foundations[1].cards == [
                .init(rank: .jack, suit: .hearts),
                .init(rank: .queen, suit: .hearts)
            ])
            #expect(subject.state.layout.columns[0].cards == [])
            #expect(subject.state.layout.columns[7].cards == [])
            #expect(subject.state.layout.foundations[3].cards == [.init(rank: .ace, suit: .diamonds)])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.first == oldLayout)
            #expect(subject.state.undoStack.last?.columns[7].cards == [.init(rank: .ace, suit: .diamonds)])
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.firstTapLocation == nil)
            #expect(presenter.statesPresented.last == subject.state)
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        do {
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .clubs)]
            subject.state.layout.columns[2].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [.init(rank: .ace, suit: .diamonds)]
            subject.state.layout.freeCells[0].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[1].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[2].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[3].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.unambiguousMove = false
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            var expected = subject.state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
            expected[.init(category: .column, index: 1)] = .enabled
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(subject.state.enablements == expected)
            #expect(subject.state.firstTapLocation == .init(category: .column, index: 0))
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        do {
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .king, suit: .clubs)]
            subject.state.layout.columns[2].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[3].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[4].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[5].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[6].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.columns[7].cards = [.init(rank: .ace, suit: .diamonds)]
            subject.state.layout.freeCells[0].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[1].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[2].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.layout.freeCells[3].cards = [.init(rank: .king, suit: .diamonds)]
            subject.state.unambiguousMove = true // *
            subject.state.redoStack = [Layout()]
            let oldLayout = subject.state.layout
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.layout.columns[0].isEmpty)
            #expect(subject.state.layout.columns[1].cards == [
                .init(rank: .king, suit: .clubs),
                .init(rank: .queen, suit: .hearts),
            ])
            #expect(subject.state.layout.columns[7].isEmpty)
            #expect(subject.state.layout.foundations[3].cards == [.init(rank: .ace, suit: .diamonds)])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.first == oldLayout)
            #expect(subject.state.undoStack.last?.columns[7].cards == [.init(rank: .ace, suit: .diamonds)])
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.firstTapLocation == nil)
            #expect(presenter.statesPresented.last == subject.state)
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        do {
            // much simpler example!
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.unambiguousMove = true
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.layout.columns[0].cards.isEmpty)
            #expect(subject.state.layout.freeCells[0].cards == [.init(rank: .queen, suit: .hearts)])
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented.last == subject.state)
        }
    }

    @Test("tapped: unambiguous edge case: if there are multiple moves to empty columns, moves to first one")
    func unambiguousEdgeCase() async {
        do {
            subject.state.layout.freeCells[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.unambiguousMove = true
            await subject.receive(.tapped(.init(category: .freeCell, index: 0)))
            #expect(subject.state.layout.freeCells[0].isEmpty)
            #expect(subject.state.layout.columns[0].cards == [.init(rank: .queen, suit: .hearts)])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        do {
            subject.state.layout.freeCells[0].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.freeCells[1].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.freeCells[2].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.freeCells[3].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.layout.columns[7].cards = [
                .init(rank: .three, suit: .clubs),
                .init(rank: .three, suit: .hearts)
            ]
            subject.state.unambiguousMove = true
            await subject.receive(.tapped(.init(category: .column, index: 7)))
            #expect(subject.state.layout.columns[7].cards == [.init(rank: .three, suit: .clubs)])
            #expect(subject.state.layout.columns[0].cards == [.init(rank: .three, suit: .hearts)])
        }
    }

    @Test("tapped: if firstTapLocation exists, if second location is any foundation, moves firstTapLocation card if movable")
    func tapSecondFoundation() async {
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [.init(rank: .six, suit: .hearts)]
            subject.state.layout.foundations[1].cards = [.init(rank: .four, suit: .hearts)]
            let oldLayout = subject.state.layout
            subject.state.autoplay = false
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .foundation, index: 0)))
            // can't put the four on the six, do nothing, end of tap-tap
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [.init(rank: .six, suit: .hearts)]
            subject.state.layout.foundations[1].cards = [.init(rank: .five, suit: .hearts)]
            subject.state.autoplay = false
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .foundation, index: 0)))
            // doesn't matter _which_ foundation the user taps on
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(subject.state.layout.foundations[1].cards == [
                .init(rank: .five, suit: .hearts),
                .init(rank: .six, suit: .hearts),
            ])
            #expect(subject.state.layout.columns[0].cards.isEmpty)
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.last == oldLayout)
            #expect(presenter.statesPresented == [subject.state])
        }
    }

    @Test("tapped: if firstTappedLocation is column, if second location is any free cell, move to first empty free cell")
    func tapSecondFreecell() async {
        do {
            // cannot move from a freecell to a freecell
            subject.state.firstTapLocation = Location(category: .freeCell, index: 0)
            subject.state.layout.freeCells[0].cards = [.init(rank: .two, suit: .clubs)]
            subject.state.layout.columns[0].cards = [.init(rank: .six, suit: .hearts)]
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            subject.state.autoplay = false
            await subject.receive(.tapped(.init(category: .freeCell, index: 3)))
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.freeCells[0].cards = [.init(rank: .two, suit: .clubs)]
            subject.state.layout.columns[0].cards = [.init(rank: .six, suit: .hearts)]
            subject.state.autoplay = false
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .freeCell, index: 3)))
            // doesn't matter which free cell is tapped second
            #expect(subject.state.layout.freeCells[1].card == .init(rank: .six, suit: .hearts))
            #expect(subject.state.layout.columns[0].cards == [])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.last == oldLayout)
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
        }
    }

    @Test("tapped: if firstTapLocation is freeCell, if secondLocation is column, move it if movable")
    func tapSecondColumnFromFreeCell() async {
        do {
            // cannot put the two on the six
            subject.state.firstTapLocation = Location(category: .freeCell, index: 0)
            subject.state.layout.freeCells[0].cards = [.init(rank: .two, suit: .clubs)]
            subject.state.layout.columns[0].cards = [.init(rank: .six, suit: .hearts)]
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            subject.state.autoplay = false
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        do {
            subject.state.firstTapLocation = Location(category: .freeCell, index: 0)
            subject.state.layout.freeCells[0].cards = [.init(rank: .five, suit: .clubs)]
            subject.state.layout.columns[0].cards = [.init(rank: .six, suit: .hearts)]
            subject.state.autoplay = false
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.layout.freeCells[0].card == nil)
            #expect(subject.state.layout.columns[0].cards == [
                .init(rank: .six, suit: .hearts),
                .init(rank: .five, suit: .clubs),
            ])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.last == oldLayout)
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
        }
    }

    @Test("tapped: if firstTapLocation is column, if second location is column, move maximum movable")
    func tapSecondColumnFromColumn() async {
        do {
            // can't put a heart on a heart
            subject.state.layout.columns[0].cards = [.init(rank: .six, suit: .hearts)]
            subject.state.layout.columns[1].cards = [.init(rank: .five, suit: .hearts)]
            subject.state.firstTapLocation = Location(category: .column, index: 1)
            let oldLayout = subject.state.layout
            subject.state.undoStack = [Layout()]
            subject.state.redoStack = [Layout()]
            subject.state.autoplay = false
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.undoStack == [Layout()])
            #expect(subject.state.redoStack == [Layout()])
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        do {
            subject.state.layout.columns[0].cards = [.init(rank: .six, suit: .hearts)]
            subject.state.layout.columns[1].cards = [
                .init(rank: .six, suit: .diamonds),
                .init(rank: .five, suit: .clubs),
                .init(rank: .four, suit: .diamonds)
            ]
            subject.state.firstTapLocation = Location(category: .column, index: 1)
            subject.state.autoplay = false
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.layout.columns[1].cards == [.init(rank: .six, suit: .diamonds)])
            #expect(subject.state.layout.columns[0].cards == [
                .init(rank: .six, suit: .hearts),
                .init(rank: .five, suit: .clubs),
                .init(rank: .four, suit: .diamonds),
            ])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.last == oldLayout)
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
        }
    }

    @Test("tapped: if firstTapLocation is column, if second location is column, if move would move all, do nothing")
    func tapSecondColumnFromColumnAll() async {
        subject.state.layout.columns[0].cards = []
        subject.state.layout.columns[1].cards = [
            .init(rank: .six, suit: .diamonds),
            .init(rank: .five, suit: .clubs),
            .init(rank: .four, suit: .diamonds)
        ]
        subject.state.firstTapLocation = Location(category: .column, index: 1)
        let oldLayout = subject.state.layout
        subject.state.autoplay = false
        subject.state.undoStack = [Layout()]
        subject.state.redoStack = [Layout()]
        await subject.receive(.tapped(.init(category: .column, index: 0)))
        #expect(subject.state.layout == oldLayout)
        #expect(subject.state.undoStack == [Layout()])
        #expect(subject.state.redoStack == [Layout()])
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.enablements == subject.state.baseEnablements)
        #expect(presenter.statesPresented == [subject.state])
    }

    @Test("tapped: if autoplay is on, second tap is followed by a round of autoplay")
    func autoplayAfterSecondTap() async {
        do {
            subject.state.layout.columns[0].cards = [.init(rank: .six, suit: .hearts)]
            subject.state.layout.columns[1].cards = [
                .init(rank: .six, suit: .diamonds),
                .init(rank: .five, suit: .clubs),
                .init(rank: .four, suit: .diamonds)
            ]
            subject.state.layout.columns[2].cards = [.init(rank: .two, suit: .spades)]
            subject.state.layout.freeCells[0].cards = [.init(rank: .three, suit: .spades)]
            subject.state.layout.foundations[0].cards = [.init(rank: .ace, suit: .spades)]
            subject.state.firstTapLocation = Location(category: .column, index: 1)
            subject.state.autoplay = false // *
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.layout.columns[1].cards == [.init(rank: .six, suit: .diamonds)])
            #expect(subject.state.layout.columns[0].cards == [
                .init(rank: .six, suit: .hearts),
                .init(rank: .five, suit: .clubs),
                .init(rank: .four, suit: .diamonds),
            ])
            #expect(subject.state.layout.columns[2].cards == [.init(rank: .two, suit: .spades)])
            #expect(subject.state.layout.freeCells[0].cards == [.init(rank: .three, suit: .spades)])
            #expect(subject.state.layout.foundations[0].cards == [.init(rank: .ace, suit: .spades)])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.last == oldLayout)
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
        }
        subject.state.firstTapLocation = nil
        presenter.statesPresented = []
        subject.state.layout = Layout()
        subject.state.undoStack = []
        do {
            subject.state.layout.columns[0].cards = [.init(rank: .six, suit: .hearts)]
            subject.state.layout.columns[1].cards = [
                .init(rank: .six, suit: .diamonds),
                .init(rank: .five, suit: .clubs),
                .init(rank: .four, suit: .diamonds)
            ]
            subject.state.layout.columns[2].cards = [.init(rank: .two, suit: .spades)] // *
            subject.state.layout.freeCells[0].cards = [.init(rank: .three, suit: .spades)] // *
            subject.state.layout.foundations[0].cards = [.init(rank: .ace, suit: .spades)]
            subject.state.layout.foundations[1].cards = [.init(rank: .ace, suit: .hearts)]
            subject.state.layout.foundations[3].cards = [.init(rank: .ace, suit: .diamonds)]
            subject.state.firstTapLocation = Location(category: .column, index: 1)
            subject.state.autoplay = true // *
            let oldLayout = subject.state.layout
            subject.state.redoStack = [Layout()]
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.layout.columns[1].cards == [.init(rank: .six, suit: .diamonds)])
            #expect(subject.state.layout.columns[0].cards == [
                .init(rank: .six, suit: .hearts),
                .init(rank: .five, suit: .clubs),
                .init(rank: .four, suit: .diamonds),
            ])
            #expect(subject.state.layout.columns[2].cards == [])
            #expect(subject.state.layout.freeCells[0].cards == [])
            #expect(subject.state.layout.foundations[0].cards == [
                .init(rank: .ace, suit: .spades),
                .init(rank: .two, suit: .spades),
                .init(rank: .three, suit: .spades),
            ])
            #expect(subject.state.layout.foundations[1].cards == [.init(rank: .ace, suit: .hearts)])
            #expect(subject.state.layout.foundations[3].cards == [.init(rank: .ace, suit: .diamonds)])
            #expect(subject.state.redoStack.isEmpty)
            #expect(subject.state.undoStack.first == oldLayout)
            #expect(subject.state.undoStack.last?.foundations[0].cards == [.init(rank: .ace, suit: .spades)])
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented.count == 2)
            #expect(presenter.statesPresented.last == subject.state)
        }
    }

    @Test("receive undo: if undo stack not empty, move one undo layout to layout and layout to redo")
    func undo() async {
        do {
            subject.state.firstTapLocation = .init(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            let oldState = subject.state
            await subject.receive(.undo)
            #expect(subject.state == oldState)
            #expect(subject.state.redoStack.isEmpty)
            #expect(presenter.statesPresented.isEmpty)
        }
        do {
            subject.state.firstTapLocation = .init(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            var undoLayout1 = Layout()
            undoLayout1.columns[1].cards = [.init(rank: .queen, suit: .hearts)]
            var undoLayout2 = Layout()
            undoLayout2.columns[2].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.undoStack.append(undoLayout2)
            subject.state.undoStack.append(undoLayout1)
            await subject.receive(.undo)
            #expect(subject.state.redoStack.first?.columns[0].cards == [.init(rank: .queen, suit: .hearts)])
            #expect(subject.state.layout.columns[0].cards == [])
            #expect(subject.state.layout.columns[1].cards == [.init(rank: .queen, suit: .hearts)])
            #expect(subject.state.undoStack.last?.columns[0].cards == [])
            #expect(subject.state.undoStack.last?.columns[1].cards == [])
            #expect(subject.state.undoStack.last?.columns[2].cards == [.init(rank: .queen, suit: .hearts)])
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
        }
    }

    @Test("receive undoAll: if undo stack not empty, moves undo layouts to redo, last one to layout")
    func undoAll() async {
        do {
            subject.state.firstTapLocation = .init(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            let oldState = subject.state
            await subject.receive(.undoAll)
            #expect(subject.state == oldState)
            #expect(subject.state.redoStack.isEmpty)
            #expect(presenter.statesPresented.isEmpty)
        }
        do {
            subject.state.firstTapLocation = .init(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            var undoLayout1 = Layout()
            undoLayout1.columns[1].cards = [.init(rank: .queen, suit: .hearts)]
            var undoLayout2 = Layout()
            undoLayout2.columns[2].cards = [.init(rank: .queen, suit: .hearts)]
            subject.state.undoStack.append(undoLayout2)
            subject.state.undoStack.append(undoLayout1)
            await subject.receive(.undoAll)
            #expect(subject.state.redoStack.first?.columns[0].cards == [.init(rank: .queen, suit: .hearts)])
            #expect(subject.state.redoStack.last?.columns[0].cards == [])
            #expect(subject.state.redoStack.last?.columns[1].cards == [.init(rank: .queen, suit: .hearts)])
            #expect(subject.state.layout.columns[0].cards == [])
            #expect(subject.state.layout.columns[1].cards == [])
            #expect(subject.state.layout.columns[2].cards == [.init(rank: .queen, suit: .hearts)])
            #expect(subject.state.undoStack == [])
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.enablements == subject.state.baseEnablements)
            #expect(presenter.statesPresented == [subject.state])
        }
    }

}
