import Foundation

/// The public face of our Stopwatch type, so we can mock it for testing.
protocol StopwatchType {
    var state: Stopwatch.State { get }
    var elapsedTime: TimeInterval { get }
    func advance() async
    func pause() async
    func reset(to: TimeInterval) async
    func resumeIfPaused() async
    func start() async
    func stop() async
}

extension StopwatchType {
    func reset() async {
        await reset(to: 0)
    }
}

/// Pausable stopwatch which you can glance at at any moment
/// and discover how much time has elapsed since start.
final class Stopwatch: StopwatchType {
    weak var delegate: (any StopwatchDelegate)?

    var state: State = .stopped

    /// The time to display. This is how long we have been running since `start`. The trick
    /// is to take account of pauses.
    var elapsedTime: TimeInterval = 0

    /// The wall time at which we last updated the time; thus, the elapsed time is always
    /// correct if it compares this to `now`.
    var whenWeLastUpdated: (any DateType)?

    init(delegate: (any StopwatchDelegate)?) {
        self.delegate = delegate
    }

    /// The heart of the stopwatch: it keeps the `elapsedTime` and `whenWeLastUpdated` in sync.
    /// First, update the `elapsedTime` as the amount of time now since the _last_ time
    /// `whenWeLastUpdated` was changed. Then change the `whenWeLastUpdated` to now. The two
    /// have thus advanced together, waiting for the next advance.
    func advance() async {
        guard state == .running else {
            return
        }
        guard let whenWeLastUpdated else {
            return
        }
        elapsedTime += services.dateType.init().timeIntervalSince(whenWeLastUpdated)
        self.whenWeLastUpdated = services.dateType.init()
        await delegate?.stopwatchDidUpdate(elapsedTime)
    }

    /// Stop and show the current elapsed time.
    func stop() async {
        await advance()
        state = .stopped
    }

    /// Stop and set the elapsed time and display it. We are messing with Time here, so we
    /// do not `advance`, but we do update `whenWeLastUpdated` so the next advance will be correct.
    /// - Parameter elapsedTime: The time to set the stopwatch to. This is so we can use a
    /// `reset` call at launch if we are displaying a saved game.
    func reset(to elapsedTime: TimeInterval = 0) async {
        state = .stopped
        self.elapsedTime = elapsedTime
        whenWeLastUpdated = services.dateType.init()
        await delegate?.stopwatchDidUpdate(elapsedTime)
    }

    /// Pause and show the current elapsed time.
    func pause() async {
        guard state == .running else {
            return
        }
        await advance()
        state = .paused
    }

    /// Resume from a paused state and show the elapsed time. Note that we do not `advance`;
    /// we just show the elapsed time from when we paused. But we update `whenWeLastUpdated`,
    /// so the _next_ advance will be correct.
    func resumeIfPaused() async {
        guard state == .paused else {
            return
        }
        state = .running
        whenWeLastUpdated = services.dateType.init()
        await delegate?.stopwatchDidUpdate(elapsedTime)
    }

    /// Start running from the current time, then wait one second and display the elapsed time.
    /// In this way, the user sees immediately that the stopwatch is running.
    func start() async {
        state = .running
        whenWeLastUpdated = services.dateType.init()
        await delegate?.stopwatchDidUpdate(elapsedTime)
        try? await unlessTesting {
            try? await Task.sleep(for: .seconds(1))
        }
        await advance()
    }

    enum State {
        case stopped
        case paused
        case running
    }
}

extension Stopwatch {
    /// Formatter that shows the elapsed time as a string. Static because they are expensive
    /// to create.
    static let timeTakenFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.allowsFractionalUnits = false
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
}

protocol StopwatchDelegate: AnyObject, Sendable {
    /// Tell the delegate the current elapsed time to display.
    func stopwatchDidUpdate(_: TimeInterval) async
}
