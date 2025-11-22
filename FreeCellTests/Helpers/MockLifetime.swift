@testable import FreeCell
import UIKit

@Observable
final class MockLifetime: LifetimeType {
    var methodsCalled = [String]()

    var event: LifetimeEvent?

    func didBecomeActive() {
        methodsCalled.append(#function)
    }

    func willResignActive() {
        methodsCalled.append(#function)
    }

    func didEnterBackground() {
        methodsCalled.append(#function)
    }

}
