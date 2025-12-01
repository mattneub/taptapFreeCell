import UIKit
import BackgroundTasks

/// The single Services instance is rooted here.
@MainActor
var services = Services()

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Register the cleanup task. Note that this merely _registers_ the task; this can do no
        // harm, even after the task has been run, because if we never again _submit_ the task,
        // it will never again be _run_.
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.neuburg.matt.freecell.cleanup", using: nil) { @Sendable task in
            Task { @Sendable in
                await services.stats.cleanup(task: task)
            }
        }
        return true
    }
}

extension BGTask: @retroactive @unchecked Sendable {}
