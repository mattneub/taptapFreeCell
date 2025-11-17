@testable import FreeCell
import Foundation

final class MockStopwatch: StopwatchType {
    var state: Stopwatch.State = .running
    var fromTimeInterval: TimeInterval?
    var methodsCalled = [String]()

    func advance() async {
        methodsCalled.append(#function)
    }

    func reset() async {
        methodsCalled.append(#function)
    }

    func resumeIfPaused() async {
        methodsCalled.append(#function)
    }

    func start(from: TimeInterval) async {
        methodsCalled.append(#function)
        self.fromTimeInterval = from
    }

    func stop() async {
        methodsCalled.append(#function)
    }


}
