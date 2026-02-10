
/// A state machine is a class that has a state and can proceed to the next state by asking
/// its state to generate the next state and making _that_ its state. That's all it does, and
/// all it needs to do; the client "drives" the succession of states by calling
/// `proceedToNextState`, and the states themselves know what state comes next.
protocol EndgameStateMachineType: AnyObject {
    var currentState: (any EndgameStateType)? { get }
    func proceedToNextState() -> (any EndgameStateType)?
}

final class EndgameStateMachine: EndgameStateMachineType {
    var currentState: (any EndgameStateType)?

    var previousState: (any EndgameStateType)?

    /// Private in order to force the client to use the StateMachineFactory to make a state machine.
    /// This is so that we can test the client's interaction with the state machine by injecting
    /// a mock.
    fileprivate init(initialLayout: Layout) {
        self.currentState = Splat(initialLayout: initialLayout, index: 0)
    }

    func proceedToNextState() -> (any EndgameStateType)? {
        let nextState = currentState?.nextState()
        if nextState != nil {
            currentState = nextState
        }
        return nextState
    }
}

/// A state machine factory is a simple object that makes a state machine. We use this architecture
/// so that we can inject our own state machine mock for testing purposes.
protocol EndgameStateMachineFactoryType {
    func makeStateMachine(initialLayout: Layout) -> any EndgameStateMachineType
}

struct EndgameStateMachineFactory: EndgameStateMachineFactoryType {
    func makeStateMachine(initialLayout: Layout) -> any EndgameStateMachineType {
        return EndgameStateMachine(initialLayout: initialLayout)
    }
}
