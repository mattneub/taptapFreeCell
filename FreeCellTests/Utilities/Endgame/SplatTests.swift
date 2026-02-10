@testable import TTFreeCell
import Testing
import Foundation

private struct SplatTests {
    let subject: EndgameStateMachine.Splat!
    let helper = MockEndgameHelper()
    var inputLayout = Layout()

    init() {
        inputLayout.columns[0].cards = [Card(rank: .two, suit: .clubs)]
        subject = EndgameStateMachine.Splat(
            initialLayout: inputLayout,
            index: 4,
            helper: helper
        )
    }

    @Test("nextState: calls helper splat with last layout passed in, index")
    func helperSplat() {
        _ = subject.nextState()
        #expect(helper.methodsCalled == ["splat(layout:index:)"])
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

    @Test("nextState: if helper not a win, returns autoplay, input layout plus helper layout, backtracking to Shift same index")
    func helperNoWin() throws {
        var layout = Layout()
        layout.columns[0].cards = [Card(rank: .three, suit: .clubs)]
        helper.layoutToReturn = layout
        let result = subject.nextState()
        let auto = try #require(result as? EndgameStateMachine.Autoplay)
        #expect(auto.accumulatedLayouts == [layout])
        let backtrack = try #require(auto.backtrackState as? EndgameStateMachine.Shift)
        #expect(backtrack.initialLayout == inputLayout)
        #expect(backtrack.index == 4)
    }

    @Test("nextState: if helper returns identical layout to input, returns Shift with same index")
    func helperNoWinIdentical() throws {
        helper.layoutToReturn = inputLayout
        let result = subject.nextState()
        let splat = try #require(result as? EndgameStateMachine.Shift)
        #expect(splat.initialLayout == subject.initialLayout)
        #expect(splat.index == 4)
    }
}
