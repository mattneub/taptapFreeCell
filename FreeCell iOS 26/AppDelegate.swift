import UIKit
import os.log

/// The single Services instance is rooted here.
@MainActor
var services = Services()

let logger = Logger(subsystem: "freecell", category: "debugging")

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return true
    }
}
