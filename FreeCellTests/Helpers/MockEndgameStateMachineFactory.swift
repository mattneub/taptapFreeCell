@testable import TTFreeCell

final class MockEndgameStateMachineFactory: EndgameStateMachineFactoryType {
    var methodsCalled = [String]()
    let stateMachineToReturn: any EndgameStateMachineType
    var layout: Layout?

    init(stateMachine: any EndgameStateMachineType) {
        self.stateMachineToReturn = stateMachine
    }

    func makeStateMachine(initialLayout: Layout) -> any EndgameStateMachineType {
        self.methodsCalled.append(#function)
        self.layout = initialLayout
        return stateMachineToReturn
    }

}
