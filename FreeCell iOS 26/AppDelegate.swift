import UIKit
import os.log

/// The single Services instance is rooted here.
@MainActor
var services = Services()

let logger = Logger(subsystem: "freecell", category: "debugging")

/// Maximum width for our layout, no matter how wide the window/view may be.
let MAXWIDTH: CGFloat = 700

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return true
    }
}
