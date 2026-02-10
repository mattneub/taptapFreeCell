@testable import TTFreeCell
import Testing
import Foundation

private struct Autoplay3Tests {
    let subject: EndgameStateMachine.Autoplay3!
    let helper = MockEndgameHelper()
    var inputLayout = Layout()

    init() {
        inputLayout.columns[0].cards = [Card(rank: .two, suit: .clubs)]
        subject = EndgameStateMachine.Autoplay3(
            accumulatedLayouts: [Layout(), Layout(), inputLayout],
            backtrackState: MockEndgameState(),
            helper: helper
        )
    }

    @Test("nextState: calls helper autoplay with last layout passed in")
    func helperAutoplay() {
        _ = subject.nextState()
        #expect(helper.methodsCalled == ["autoplay(layout:)"])
        #expect(helper.layoutPassedIn == inputLayout)
    }

    @Test("nextState: if helper returns a win, returns OutcomeWin with input layouts plus helper layout")
    func helperWin() throws {
        var layout = Layout()
        layout.foundations[0].cards = [Card(rank: .two, suit: .clubs)]
        helper.layoutToReturn = layout
        let result = subject.nextState()
        let win = try #require(result as? EndgameStateMachine.OutcomeWin)
        #expect(win.accumulatedLayouts == [Layout(), Layout(), inputLayout, layout])
    }

    @Test("nextState: if helper returns not a win, backtracks")
    func helperNoWin() throws {
        var layout = Layout()
        layout.columns[0].cards = [Card(rank: .three, suit: .clubs)]
        helper.layoutToReturn = layout
        let result = subject.nextState()
        #expect(result is MockEndgameState)
    }
}
