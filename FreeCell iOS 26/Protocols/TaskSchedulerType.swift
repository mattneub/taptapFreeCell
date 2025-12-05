import BackgroundTasks

protocol TaskSchedulerType: Sendable {
    func register(
        forTaskWithIdentifier identifier: String,
        using queue: dispatch_queue_t?,
        launchHandler: @escaping (BGTask) -> Void
    ) -> Bool
    func submit(_: BGTaskRequest) throws
}

extension BGTaskScheduler: TaskSchedulerType {}

protocol BackgroundTaskType: AnyObject, Sendable {
    var expirationHandler: (() -> Void)? { get set }
    func setTaskCompleted(success: Bool)
}

extension BGTask: BackgroundTaskType {}
