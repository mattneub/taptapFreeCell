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
}
