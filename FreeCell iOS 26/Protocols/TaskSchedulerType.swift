import BackgroundTasks

protocol TaskSchedulerType: Sendable {
    func submit(_: BGTaskRequest) throws
}

extension BGTaskScheduler: TaskSchedulerType {}

nonisolated
protocol BackgroundTaskType: AnyObject, Sendable {
    var expirationHandler: (() -> Void)? { get set }
    func setTaskCompleted(success: Bool)
}

extension BGTask: nonisolated BackgroundTaskType {}
