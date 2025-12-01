@testable import TTFreeCell
import Foundation
import BackgroundTasks

final class MockTaskScheduler: TaskSchedulerType {
    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var request: BGTaskRequest?

    func submit(_ request: BGTaskRequest) throws {
        methodsCalled.append(#function)
        self.request = request
    }
}
