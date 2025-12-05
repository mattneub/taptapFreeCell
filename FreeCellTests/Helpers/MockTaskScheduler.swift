@testable import TTFreeCell
import Foundation
import BackgroundTasks

final class MockTaskScheduler: TaskSchedulerType {
    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var request: BGTaskRequest?
    nonisolated(unsafe) var identifier: String?
    nonisolated(unsafe) var launchHandler: ((BGTask) -> Void)?

    func register(
        forTaskWithIdentifier identifier: String,
        using queue: dispatch_queue_t?,
        launchHandler: @escaping (BGTask) -> Void
    ) -> Bool {
        methodsCalled.append(#function)
        self.identifier = identifier
        self.launchHandler = launchHandler
        return true
    }

    func submit(_ request: BGTaskRequest) throws {
        methodsCalled.append(#function)
        self.request = request
    }
}
