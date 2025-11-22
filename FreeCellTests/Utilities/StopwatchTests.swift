@testable import FreeCell
import Testing
import Foundation

struct StopwatchTests {
    fileprivate let delegate = MockStopwatchDelegate()
    var subject: Stopwatch!
    let lastUpdated = MockDate()

    init() {
        subject = Stopwatch(delegate: delegate)
        services.date = MockDate.self
        subject.state = .running
        MockDate.timeIntervalToReturn = 100
        subject.elapsedTime = 50
        subject.whenWeLastUpdated = lastUpdated
    }

    @Test("advance: behaves correctly")
    func advance() async throws {
        await subject.advance()
        #expect(subject.elapsedTime == 150) // proving they were added together
        let subjectLastUpdated = try #require(subject.whenWeLastUpdated as? MockDate)
        #expect(subjectLastUpdated.uuid != lastUpdated.uuid) // proving it's a new "date" instance
        #expect(delegate.methodsCalled == ["stopwatchDidUpdate(_:)"])
        #expect(delegate.timeInterval == 150)
        #expect(subject.state == .running)
    }

    @Test("advance: if state is paused, does nothing")
    func advanceStatePaused() async throws {
        subject.state = .paused
        await subject.advance()
        #expect(subject.elapsedTime == 50) // unchanged
        let subjectLastUpdated = try #require(subject.whenWeLastUpdated as? MockDate)
        #expect(subjectLastUpdated.uuid == lastUpdated.uuid) // unchanged
        #expect(delegate.methodsCalled == [])
        #expect(subject.state == .paused)
    }

    @Test("advance: if state is stopped, does nothing")
    func advanceStateStopped() async throws {
        subject.state = .stopped
        await subject.advance()
        #expect(subject.elapsedTime == 50) // unchanged
        let subjectLastUpdated = try #require(subject.whenWeLastUpdated as? MockDate)
        #expect(subjectLastUpdated.uuid == lastUpdated.uuid) // unchanged
        #expect(delegate.methodsCalled == [])
        #expect(subject.state == .stopped)
    }

    @Test("stop: just like `advance` except the stopwatch is stopped")
    func stop() async throws {
        await subject.stop()
        #expect(subject.elapsedTime == 150) // proving they were added together
        let subjectLastUpdated = try #require(subject.whenWeLastUpdated as? MockDate)
        #expect(subjectLastUpdated.uuid != lastUpdated.uuid) // proving it's a new "date" instance
        #expect(delegate.methodsCalled == ["stopwatchDidUpdate(_:)"])
        #expect(delegate.timeInterval == 150)
        #expect(subject.state == .stopped)
    }

    @Test("reset: just like `stop` except that the elapsedTime and delegate time is zero by default")
    func reset() async throws {
        await subject.reset()
        #expect(subject.elapsedTime == 0)
        let subjectLastUpdated = try #require(subject.whenWeLastUpdated as? MockDate)
        #expect(subjectLastUpdated.uuid != lastUpdated.uuid) // proving it's a new "date" instance
        #expect(delegate.methodsCalled == ["stopwatchDidUpdate(_:)"])
        #expect(delegate.timeInterval == 0)
        #expect(subject.state == .stopped)
    }

    @Test("resetTo: just like `stop` except that the elapsedTime and delegate time is given time")
    func resetTo() async throws {
        await subject.reset(to: 100)
        #expect(subject.elapsedTime == 100)
        let subjectLastUpdated = try #require(subject.whenWeLastUpdated as? MockDate)
        #expect(subjectLastUpdated.uuid != lastUpdated.uuid) // proving it's a new "date" instance
        #expect(delegate.methodsCalled == ["stopwatchDidUpdate(_:)"])
        #expect(delegate.timeInterval == 100)
        #expect(subject.state == .stopped)
    }

    @Test("pause: just like `advance` except the stopwatch is paused")
    func pause() async throws {
        await subject.pause()
        #expect(subject.elapsedTime == 150) // proving they were added together
        let subjectLastUpdated = try #require(subject.whenWeLastUpdated as? MockDate)
        #expect(subjectLastUpdated.uuid != lastUpdated.uuid) // proving it's a new "date" instance
        #expect(delegate.methodsCalled == ["stopwatchDidUpdate(_:)"])
        #expect(delegate.timeInterval == 150)
        #expect(subject.state == .paused)
    }

    @Test("pause: if state is paused, does nothing")
    func pausePaused() async throws {
        subject.state = .paused
        await subject.pause()
        #expect(subject.elapsedTime == 50) // unchanged
        let subjectLastUpdated = try #require(subject.whenWeLastUpdated as? MockDate)
        #expect(subjectLastUpdated.uuid == lastUpdated.uuid) // unchanged
        #expect(delegate.methodsCalled == [])
        #expect(subject.state == .paused)
    }

    @Test("pause: if state is stopped, does nothing")
    func pauseStateStopped() async throws {
        subject.state = .stopped
        await subject.pause()
        #expect(subject.elapsedTime == 50) // unchanged
        let subjectLastUpdated = try #require(subject.whenWeLastUpdated as? MockDate)
        #expect(subjectLastUpdated.uuid == lastUpdated.uuid) // unchanged
        #expect(delegate.methodsCalled == [])
        #expect(subject.state == .stopped)
    }

    @Test("resumeIfPaused: goes from paused to running, updates `lastUpdated` but sends _old_ `elapsedTime`")
    func resumeIfPaused() async throws {
        subject.state = .paused
        await subject.resumeIfPaused()
        #expect(subject.elapsedTime == 50) // the old value
        let subjectLastUpdated = try #require(subject.whenWeLastUpdated as? MockDate)
        #expect(subjectLastUpdated.uuid != lastUpdated.uuid) // proving it's a new "date" instance
        #expect(delegate.methodsCalled == ["stopwatchDidUpdate(_:)"])
        #expect(delegate.timeInterval == 50)
        #expect(subject.state == .running)
    }

    @Test("resumeIfPaused: if running, does nothing")
    func resumeIfPausedStateRunning() async throws {
        subject.state = .running
        await subject.resumeIfPaused()
        #expect(subject.elapsedTime == 50) // the old value
        let subjectLastUpdated = try #require(subject.whenWeLastUpdated as? MockDate)
        #expect(subjectLastUpdated.uuid == lastUpdated.uuid) // unchanged
        #expect(delegate.methodsCalled == [])
        #expect(subject.state == .running)
    }

    @Test("resumeIfPaused: if stopped, does nothing")
    func resumeIfPausedStateStopped() async throws {
        subject.state = .stopped
        await subject.resumeIfPaused()
        #expect(subject.elapsedTime == 50) // the old value
        let subjectLastUpdated = try #require(subject.whenWeLastUpdated as? MockDate)
        #expect(subjectLastUpdated.uuid == lastUpdated.uuid) // unchanged
        #expect(delegate.methodsCalled == [])
        #expect(subject.state == .stopped)
    }

    @Test("start: sets state to running, then like `advance` but adds `lastUpdated` to argument")
    func start() async throws {
        subject.state = .stopped
        await subject.start()
        #expect(subject.elapsedTime == 150) // proving they were added together
        let subjectLastUpdated = try #require(subject.whenWeLastUpdated as? MockDate)
        #expect(subjectLastUpdated.uuid != lastUpdated.uuid) // proving it's a new "date" instance
        #expect(delegate.methodsCalled == ["stopwatchDidUpdate(_:)", "stopwatchDidUpdate(_:)"])
        #expect(delegate.timeInterval == 150)
        #expect(subject.state == .running)
    }

    @Test("formatter gives the right string")
    func formatter() throws {
        let formatter = Stopwatch.timeTakenFormatter
        let dateComponents = DateComponents(hour: 1, minute: 1, second: 1)
        #expect(formatter.string(from: dateComponents) == "01:01:01")
    }
}

fileprivate final class MockStopwatchDelegate: StopwatchDelegate {
    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var timeInterval: TimeInterval?

    func stopwatchDidUpdate(_ timeInterval: TimeInterval) async {
        methodsCalled.append(#function)
        self.timeInterval = timeInterval
    }

}
