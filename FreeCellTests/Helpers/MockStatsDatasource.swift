import Foundation
@testable import TTFreeCell

final class MockStatsDatasource: NSObject, @MainActor StatsDatasourceType {
    typealias State = StatsState

    var methodsCalled = [String]()
    var statesPresented = [StatsState]()

    func present(_ state: StatsState) async {
        methodsCalled.append(#function)
        statesPresented.append(state)
    }
}
