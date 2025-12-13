import Foundation
@testable import TTFreeCell

final class MockPrefsDatasource: NSObject, @MainActor PrefsDatasourceType {
    typealias State = PrefsState
    typealias Received = PrefsEffect

    var methodsCalled = [String]()
    var statesPresented = [PrefsState]()
    var thingsReceived = [PrefsEffect]()

    func present(_ state: PrefsState) async {
        methodsCalled.append(#function)
        statesPresented.append(state)
    }

    func receive(_ effect: PrefsEffect) async {
        methodsCalled.append(#function)
        thingsReceived.append(effect)
    }
}
