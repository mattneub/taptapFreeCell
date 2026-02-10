@testable import TTFreeCell
import Testing
import Foundation

private struct ShiftTests {
    let subject: EndgameStateMachine.Shift!
    let helper = MockEndgameHelper()
    var inputLayout = Layout()

    init() {
        inputLayout.columns[0].cards = [Card(rank: .two, suit: .clubs)]
        subject = EndgameStateMachine.Shift(
            initialLayout: inputLayout,
            index: 4,
            helper: helper
        )
    }

    @Test("nextState: calls helper shift with last layout passed in, index")
    func helperShift() {
        _ = subject.nextState()
        #expect(helper.methodsCalled == ["shift(layout:index:)"])
        #expect(helper.index == 4)
        #expect(helper.layoutPassedIn == inputLayout)
    }

    @Test("nextState: if helper returns a win, returns OutcomeWin with helper layout")
    func helperWin() throws {
        var layout = Layout()
        layout.foundations[0].cards = [Card(rank: .two, suit: .clubs)]
        helper.layoutToReturn = layout
        let result = subject.nextState()
        let win = try #require(result as? EndgameStateMachine.OutcomeWin)
        #expect(win.accumulatedLayouts == [layout])
    }

    @Test("nextState: if helper not a win, returns autoplay, input layout plus helper layout, backtracking to Splat next index")
    func helperNoWin() throws {
        var layout = Layout()
        layout.columns[0].cards = [Card(rank: .three, suit: .clubs)]
        helper.layoutToReturn = layout
        let result = subject.nextState()
        let auto = try #require(result as? EndgameStateMachine.Autoplay)
        #expect(auto.accumulatedLayouts == [layout])
        let backtrack = try #require(auto.backtrackState as? EndgameStateMachine.Splat)
        #expect(backtrack.initialLayout == inputLayout)
        #expect(backtrack.index == 5)
    }

    @Test("nextState: if helper not a win and index is 7, same as preceding but backtracking to OutcomeLose")
    func helperNoWinLastIndex() throws {
        let subject = EndgameStateMachine.Shift(
            initialLayout: inputLayout,
            index: 7,
            helper: helper
        )
        var layout = Layout()
        layout.columns[0].cards = [Card(rank: .three, suit: .clubs)]
        helper.layoutToReturn = layout
        let result = subject.nextState()
        let auto = try #require(result as? EndgameStateMachine.Autoplay)
        #expect(auto.accumulatedLayouts == [layout])
        #expect(auto.backtrackState is EndgameStateMachine.OutcomeLose)
    }

    @Test("nextState: if helper returns identical layout to input, returns Splat with next index")
    func helperNoWinIdentical() throws {
        helper.layoutToReturn = inputLayout
        let result = subject.nextState()
        let splat = try #require(result as? EndgameStateMachine.Splat)
        #expect(splat.initialLayout == subject.initialLayout)
        #expect(splat.index == 5)
    }

    @Test("nextState: if helper returns identical and index is 7, loses")
    func helperNoWinIdenticalLastIndex() throws {
        let subject = EndgameStateMachine.Shift(
            initialLayout: inputLayout,
            index: 7,
            helper: helper
        )
        helper.layoutToReturn = inputLayout
        let result = subject.nextState()
        #expect(result is EndgameStateMachine.OutcomeLose)
    }

}
