@testable import TTFreeCell
import Testing
import Foundation

private struct OutcomeLoseTests {
    let subject = EndgameStateMachine.OutcomeLose()

    @Test("nextState: produces nil")
    func nextState() {
        let result = subject.nextState()
        #expect(result == nil)
    }
}
