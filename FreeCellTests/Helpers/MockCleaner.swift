@testable import TTFreeCell
import UIKit

final class MockCleaner: CleanerType {
    var methodsCalled = [String]()
    var task: (any BackgroundTaskType)?

    func register() {
        methodsCalled.append(#function)
    }
    
    func cleanup(task: (any BackgroundTaskType)?) {
        methodsCalled.append(#function)
        self.task = task
    }
}
