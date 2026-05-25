import UIKit
import os.log

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    var coordinator: (any RootCoordinatorType) = RootCoordinator()

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = scene as? UIWindowScene else {
            return
        }
        scene.sizeRestrictions?.minimumSize.width = 500
        unlessTesting {
            bootstrap(scene: scene)
        }
    }

    func bootstrap(scene: UIWindowScene) {
        services.persistence.registerDefaults()
        let window = UIWindow(windowScene: scene)
        self.window = window
        coordinator.createInterface(window: window)
        window.makeKeyAndVisible()
        // uncomment to draw icon in simulator (use iPad simulator)
        // window.rootViewController = UIStoryboard(name: "IconGenerator", bundle: nil).instantiateInitialViewController()
    }

    /// See
    /// https://developer.apple.com/documentation/technotes/tn3192-Migrating-your-app-from-the-deprecated-UIRequiresFullScreen-key
    /// This is the official signal that we might need to revise our interface because the user
    /// has resized the window.
    func windowScene(
        _ windowScene: UIWindowScene,
        didUpdateEffectiveGeometry previousGeometry: UIWindowScene.Geometry
    ) {
        services.windowGeometry.geometryUpdated(scene: windowScene, coordinator: coordinator)
    }
}
