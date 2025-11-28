import Foundation
@testable import TTFreeCell

final class MockStatsDatasource: NSObject, @MainActor StatsDatasourceType {
    typealias State = StatsState
    typealias Received = StatsEffect

    var methodsCalled = [String]()
    var statesPresented = [StatsState]()
    var thingsReceived = [StatsEffect]()

    func present(_ state: StatsState) async {
        methodsCalled.append(#function)
        statesPresented.append(state)
    }

    func receive(_ effect: StatsEffect) async {
        methodsCalled.append(#function)
        thingsReceived.append(effect)
    }
}
