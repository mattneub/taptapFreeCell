@testable import TTFreeCell
import Testing
import Foundation

private struct AutoplayTests {
    let subject: EndgameStateMachine.Autoplay!
    let helper = MockEndgameHelper()
    var inputLayout = Layout()

    init() {
        inputLayout.columns[0].cards = [Card(rank: .two, suit: .clubs)]
        subject = EndgameStateMachine.Autoplay(
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

    @Test("nextState: if helper returns not a win, returns SecondPly, index 0, with input layouts plus helper layout")
    func helperNoWin() throws {
        var layout = Layout()
        layout.columns[0].cards = [Card(rank: .three, suit: .clubs)]
        helper.layoutToReturn = layout
        let result = subject.nextState()
        let ply = try #require(result as? EndgameStateMachine.SecondPly)
        #expect(ply.accumulatedLayouts == [Layout(), Layout(), inputLayout, layout])
        #expect(ply.index == 0)
        #expect(ply.backtrackState is MockEndgameState)
    }

    @Test("nextState: if helper returns identical layout to input, not appended")
    func helperNoWinIdentical() throws {
        helper.layoutToReturn = inputLayout
        let result = subject.nextState()
        let ply = try #require(result as? EndgameStateMachine.SecondPly)
        #expect(ply.accumulatedLayouts == [Layout(), Layout(), inputLayout])
        #expect(ply.index == 0)
        #expect(ply.backtrackState is MockEndgameState)
    }
}
