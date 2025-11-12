@testable import FreeCell
import Testing
import Foundation

struct GameProcessorTests {
    let subject = GameProcessor()
    let presenter = MockReceiverPresenter<GameEffect, GameState>()

    init() {
        subject.presenter = presenter
    }

    @Test("receive deal: creates a new full-deal layout, puts it in the state, and presents it")
    func deal() async {
        subject.state.firstTapLocation = .init(category: .column, index: 0)
        #expect(subject.state.layout == Layout())
        await subject.receive(.deal)
        let tableau = subject.state.layout.shlomiTableauDescription.replacing(/[\s\n]/, with: "")
        #expect(tableau.count == 104) // fifty two cards
        #expect(subject.state.firstTapLocation == nil)
        #expect(presenter.statesPresented == [subject.state])
    }

    @Test("receive tapBackground: erases existing first tap")
    func tapBackground() async {
        subject.state.firstTapLocation = .init(category: .column, index: 0)
        await subject.receive(.tapBackground)
        #expect(subject.state.firstTapLocation == nil)
        #expect(presenter.statesPresented == [subject.state])
    }

    @Test("receive autoplay: play all can-go non-needed from columns and freecells to foundations")
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
    }

    @Test("tapped: if firstTapLocation is nil, tapped location becomes firstTapLocation if not empty source, not foundation")
    func tappedFirst() async {
        do {
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.firstTapLocation == nil)
            #expect(presenter.statesPresented.isEmpty)
        }
        do {
            subject.state.layout.foundations[0].cards = [.init(rank: .ace, suit: .spades)]
            await subject.receive(.tapped(.init(category: .foundation, index: 0)))
            #expect(subject.state.firstTapLocation == nil)
            #expect(presenter.statesPresented.isEmpty)
        }
        do {
            subject.state.layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.firstTapLocation == Location(category: .column, index: 0))
            #expect(presenter.statesPresented == [subject.state])
        }
    }

    @Test("tapped: if firstTapLocation is nil, if corresponding card can be autoplayed, it is")
    func tappedFirstCanAutoplay() async {
        subject.state.layout.columns[0].cards = [
            .init(rank: .two, suit: .clubs),
            .init(rank: .ace, suit: .clubs),
        ]
        await subject.receive(.tapped(.init(category: .column, index: 0)))
        #expect(subject.state.firstTapLocation == nil)
        #expect(subject.state.layout.foundation(for: .clubs).cards == [.init(rank: .ace, suit: .clubs)])
        #expect(subject.state.layout.columns[0].cards == [.init(rank: .two, suit: .clubs)])
        #expect(presenter.statesPresented == [subject.state])
    }

    @Test("tapped: if firstTapLocation exists, if second location is any foundation, moves firstTapLocation card if movable")
    func tapSecondFoundation() async {
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [.init(rank: .six, suit: .hearts)]
            subject.state.layout.foundations[1].cards = [.init(rank: .four, suit: .hearts)]
            let oldLayout = subject.state.layout
            await subject.receive(.tapped(.init(category: .foundation, index: 0)))
            // can't put the four on the six, do nothing, end of tap-tap
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.layout == oldLayout)
            #expect(presenter.statesPresented == [subject.state])
        }
        presenter.statesPresented = []
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.columns[0].cards = [.init(rank: .six, suit: .hearts)]
            subject.state.layout.foundations[1].cards = [.init(rank: .five, suit: .hearts)]
            await subject.receive(.tapped(.init(category: .foundation, index: 0)))
            // doesn't matter _which_ foundation the user taps on
            #expect(subject.state.firstTapLocation == nil)
            #expect(subject.state.layout.foundations[1].cards == [
                .init(rank: .five, suit: .hearts),
                .init(rank: .six, suit: .hearts),
            ])
            #expect(subject.state.layout.columns[0].cards.isEmpty)
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
            await subject.receive(.tapped(.init(category: .freeCell, index: 3)))
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.firstTapLocation == nil)
            #expect(presenter.statesPresented == [subject.state])
        }
        presenter.statesPresented = []
        do {
            subject.state.firstTapLocation = Location(category: .column, index: 0)
            subject.state.layout.freeCells[0].cards = [.init(rank: .two, suit: .clubs)]
            subject.state.layout.columns[0].cards = [.init(rank: .six, suit: .hearts)]
            await subject.receive(.tapped(.init(category: .freeCell, index: 3)))
            // doesn't matter which free cell is tapped second
            #expect(subject.state.layout.freeCells[1].card == .init(rank: .six, suit: .hearts))
            #expect(subject.state.layout.columns[0].cards == [])
            #expect(subject.state.firstTapLocation == nil)
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
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.firstTapLocation == nil)
            #expect(presenter.statesPresented == [subject.state])
        }
        presenter.statesPresented = []
        do {
            subject.state.firstTapLocation = Location(category: .freeCell, index: 0)
            subject.state.layout.freeCells[0].cards = [.init(rank: .five, suit: .clubs)]
            subject.state.layout.columns[0].cards = [.init(rank: .six, suit: .hearts)]
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.layout.freeCells[0].card == nil)
            #expect(subject.state.layout.columns[0].cards == [
                .init(rank: .six, suit: .hearts),
                .init(rank: .five, suit: .clubs),
            ])
            #expect(subject.state.firstTapLocation == nil)
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
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.layout == oldLayout)
            #expect(subject.state.firstTapLocation == nil)
            #expect(presenter.statesPresented == [subject.state])
        }
        presenter.statesPresented = []
        do {
            subject.state.layout.columns[0].cards = [.init(rank: .six, suit: .hearts)]
            subject.state.layout.columns[1].cards = [
                .init(rank: .six, suit: .diamonds),
                .init(rank: .five, suit: .clubs),
                .init(rank: .four, suit: .diamonds)
            ]
            subject.state.firstTapLocation = Location(category: .column, index: 1)
            await subject.receive(.tapped(.init(category: .column, index: 0)))
            #expect(subject.state.layout.columns[1].cards == [.init(rank: .six, suit: .diamonds)])
            #expect(subject.state.layout.columns[0].cards == [
                .init(rank: .six, suit: .hearts),
                .init(rank: .five, suit: .clubs),
                .init(rank: .four, suit: .diamonds),
            ])
            #expect(subject.state.firstTapLocation == nil)
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
        await subject.receive(.tapped(.init(category: .column, index: 0)))
        #expect(subject.state.layout == oldLayout)
        #expect(subject.state.firstTapLocation == nil)
        #expect(presenter.statesPresented == [subject.state])
    }

}
