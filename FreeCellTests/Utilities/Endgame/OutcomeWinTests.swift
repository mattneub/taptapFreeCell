@testable import TTFreeCell
import Testing
import Foundation

private struct OutcomeWinTests {
    let subject = EndgameStateMachine.OutcomeWin(accumulatedLayouts: [Layout()])

    @Test("nextState: produces nil, vends the layouts handed to it")
    func nextState() {
        let result = subject.nextState()
        #expect(result == nil)
        #expect(subject.accumulatedLayouts == [Layout()])
    }
}
