@testable import TTFreeCell
import Testing
import Foundation

private struct Autoplay2Tests {
    let subject: EndgameStateMachine.Autoplay2!
    let helper = MockEndgameHelper()
    var inputLayout = Layout()

    init() {
        inputLayout.columns[0].cards = [Card(rank: .two, suit: .clubs)]
        subject = EndgameStateMachine.Autoplay2(
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

    @Test("nextState: if helper returns not a win, returns ThirdPly, index 0, with input layouts plus helper layout")
    func helperNoWin() throws {
        var layout = Layout()
        layout.columns[0].cards = [Card(rank: .three, suit: .clubs)]
        helper.layoutToReturn = layout
        let result = subject.nextState()
        let ply = try #require(result as? EndgameStateMachine.ThirdPly)
        #expect(ply.accumulatedLayouts == [Layout(), Layout(), inputLayout, layout])
        #expect(ply.index == 0)
    }

    @Test("nextState: if helper returns identical layout to input, not appended")
    func helperNoWinIdentical() throws {
        helper.layoutToReturn = inputLayout
        let result = subject.nextState()
        let ply = try #require(result as? EndgameStateMachine.ThirdPly)
        #expect(ply.accumulatedLayouts == [Layout(), Layout(), inputLayout])
        #expect(ply.index == 0)
    }

    @Test("nextState: if helper returns not a win but insufficient layouts, backtracks")
    func helperNoWinTwoInputs() throws {
        var layout = Layout()
        layout.columns[0].cards = [Card(rank: .three, suit: .clubs)]
        do {
            helper.layoutToReturn = layout
            let subject = EndgameStateMachine.Autoplay2(
                accumulatedLayouts: [inputLayout],
                backtrackState: MockEndgameState(),
                helper: helper
            )
            let result = subject.nextState()
            #expect(result is MockEndgameState)
        }
        do {
            let subject = EndgameStateMachine.Autoplay2(
                accumulatedLayouts: [Layout(), inputLayout],
                backtrackState: MockEndgameState(),
                helper: helper
            )
            helper.layoutToReturn = layout
            let result = subject.nextState()
            #expect(result is EndgameStateMachine.ThirdPly)
        }
    }

    @Test("nextState: if helper returns not a win but too many cards, backtracks")
    func helperNoWinCardCount() throws {
        var layout = Layout()
        do {
            layout.columns[0].cards = Array(repeating: Card(rank: .three, suit: .clubs), count: 44)
            helper.layoutToReturn = layout
            let result = subject.nextState()
            #expect(result is MockEndgameState)
        }
        do {
            layout.columns[0].cards = Array(repeating: Card(rank: .three, suit: .clubs), count: 43)
            helper.layoutToReturn = layout
            let result = subject.nextState()
            #expect(result is EndgameStateMachine.ThirdPly)
        }
    }
}

