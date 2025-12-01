@testable import TTFreeCell
import Foundation

final class MockBackgroundTask: BackgroundTaskType, Sendable {
    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var success: Bool?

    nonisolated(unsafe) var expirationHandler: (() -> Void)?
    
    func setTaskCompleted(success: Bool) {
        methodsCalled.append(#function)
        self.success = success
    }
}

