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
        #expect(subject.state.layout == Layout())
        await subject.receive(.deal)
        let tableau = subject.state.layout.shlomiTableauDescription.replacing(/[\s\n]/, with: "")
        #expect(tableau.count == 104) // fifty two cards
        #expect(presenter.statesPresented == [subject.state])
    }

    @Test("receive autoplay: play all can-go non-needed from columns to foundations")
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
        subject.state.layout = layout
        await subject.receive(.autoplay)
        #expect(subject.state.layout.foundations[0].cards == [
            .init(rank: .ace, suit: .spades),
            .init(rank: .two, suit: .spades)
        ]) // did not autoplay the three, it might be needed
        #expect(subject.state.layout.foundations[2].cards == [
            .init(rank: .ace, suit: .clubs),
            .init(rank: .two, suit: .clubs)

        ]) // autoplayed the ace, then the two in another round
        #expect(subject.state.layout.columns[0].isEmpty)
        #expect(subject.state.layout.columns[1].cards == [.init(rank: .three, suit: .spades)])
    }
}
