@testable import TTFreeCell
import Testing
import Foundation

private struct SecondPlyTests {
    let subject: EndgameStateMachine.SecondPly!
    let helper = MockEndgameHelper()
    var inputLayout = Layout()

    init() {
        inputLayout.columns[0].cards = [Card(rank: .two, suit: .clubs)]
        subject = EndgameStateMachine.SecondPly(
            index: 4,
            accumulatedLayouts: [Layout(), Layout(), inputLayout],
            backtrackState: MockEndgameState(),
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

    @Test("nextState: if helper returns a win, returns OutcomeWin with input layouts plus helper layout")
    func helperWin() throws {
        var layout = Layout()
        layout.foundations[0].cards = [Card(rank: .two, suit: .clubs)]
        helper.layoutToReturn = layout
        let result = subject.nextState()
        let win = try #require(result as? EndgameStateMachine.OutcomeWin)
        #expect(win.accumulatedLayouts == [Layout(), Layout(), inputLayout, layout])
    }

    @Test("nextState: if helper not a win, returns autoplay2, input layouts plus helper layout, backtracking to SecondPly next index")
    func helperNoWin() throws {
        var layout = Layout()
        layout.columns[0].cards = [Card(rank: .three, suit: .clubs)]
        helper.layoutToReturn = layout
        let result = subject.nextState()
        let auto = try #require(result as? EndgameStateMachine.Autoplay2)
        #expect(auto.accumulatedLayouts == [Layout(), Layout(), inputLayout, layout])
        let backtrack = try #require(auto.backtrackState as? EndgameStateMachine.SecondPly)
        #expect(backtrack.index == 5)
        #expect(backtrack.accumulatedLayouts == subject.accumulatedLayouts)
        #expect(backtrack.backtrackState is MockEndgameState)
    }

    @Test("nextState: if helper not a win and index is 7, same as preceding but backtracking to our backtrack")
    func helperNoWinLastIndex() throws {
        let subject = EndgameStateMachine.SecondPly(
            index: 7,
            accumulatedLayouts: [Layout(), Layout(), inputLayout],
            backtrackState: MockEndgameState(),
            helper: helper
        )
        var layout = Layout()
        layout.columns[0].cards = [Card(rank: .three, suit: .clubs)]
        helper.layoutToReturn = layout
        let result = subject.nextState()
        let auto = try #require(result as? EndgameStateMachine.Autoplay2)
        #expect(auto.accumulatedLayouts == [Layout(), Layout(), inputLayout, layout])
        #expect(auto.backtrackState is MockEndgameState)
    }

    @Test("nextState: if helper returns identical layout to input, returns SecondPly with next index")
    func helperNoWinIdentical() throws {
        helper.layoutToReturn = inputLayout
        let result = subject.nextState()
        let ply = try #require(result as? EndgameStateMachine.SecondPly)
        #expect(ply.index == 5)
        #expect(ply.accumulatedLayouts == subject.accumulatedLayouts)
        #expect(ply.backtrackState is MockEndgameState)
    }

    @Test("nextState: if helper returns identical and index is 7, backtracks")
    func helperNoWinIdenticalLastIndex() throws {
        let subject = EndgameStateMachine.SecondPly(
            index: 7,
            accumulatedLayouts: [Layout(), Layout(), inputLayout],
            backtrackState: MockEndgameState(),
            helper: helper
        )
        helper.layoutToReturn = inputLayout
        let result = subject.nextState()
        #expect(result is MockEndgameState)
    }

}
