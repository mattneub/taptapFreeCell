@testable import TTFreeCell

final class MockEndgameStateMachine: EndgameStateMachineType {
    var methodsCalled = [String]()
    var statesToReturn: [(any EndgameStateType)?] = [nil]
    var _currentState: (any EndgameStateType)?

    var currentState: (any EndgameStateType)? {
        get {
            methodsCalled.append(#function)
            return _currentState
        }
    }

    func proceedToNextState() -> (any EndgameStateType)? {
        methodsCalled.append(#function)
        return statesToReturn.removeFirst()
    }
}
