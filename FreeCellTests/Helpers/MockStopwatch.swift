@testable import FreeCell
import Foundation

final class MockStopwatch: StopwatchType {
    var elapsedTime: TimeInterval = 0
    var state: Stopwatch.State = .running
    var resetTimeInterval: TimeInterval?
    var methodsCalled = [String]()

    func advance() async {
        methodsCalled.append(#function)
    }

    func pause() async {
        methodsCalled.append(#function)
    }

    func reset(to timeInterval: TimeInterval) async {
        methodsCalled.append(#function)
        self.resetTimeInterval = timeInterval
    }

    func resumeIfPaused() async {
        methodsCalled.append(#function)
    }

    func start() async {
        methodsCalled.append(#function)
    }

    func stop() async {
        methodsCalled.append(#function)
    }


}
