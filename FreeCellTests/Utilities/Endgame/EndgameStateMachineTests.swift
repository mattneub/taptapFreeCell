@testable import TTFreeCell
import Testing
import Foundation

private struct EndgameStateMachineTests {
    let subject: EndgameStateMachine!
    var layout = Layout()

    init() {
        let factory = EndgameStateMachineFactory()
        layout.columns[0].cards = [Card(rank: .two, suit: .clubs)]
        subject = factory.makeStateMachine(initialLayout: layout) as? EndgameStateMachine
    }

    @Test("initialize: starting state is Splat with initial layout same as handed to the factory")
    func initialize() throws {
        let currentState = try #require(subject.currentState as? EndgameStateMachine.Splat)
        #expect(currentState.initialLayout == layout)
    }

    @Test("proceedToNextState: replaces current state by its next state")
    func proceed() {
        subject.currentState = Manny()
        let result = subject.proceedToNextState()
        #expect(result is Moe)
        #expect(subject.currentState is Moe)
    }

    @Test("proceedToNextState: if current state next state is nil, returns nil and leaves current state alone")
    func proceedProducingNil() {
        subject.currentState = Moe()
        let result = subject.proceedToNextState()
        #expect(result == nil)
        #expect(subject.currentState is Moe)
    }
}

private struct Manny: EndgameStateType {
    func nextState() -> (any EndgameStateType)? {
        return Moe()
    }
}

private struct Moe: EndgameStateType {
    func nextState() -> (any EndgameStateType)? {
        return nil
    }
}
