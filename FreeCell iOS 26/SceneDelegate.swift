import UIKit

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

    func sceneDidBecomeActive(_ scene: UIScene) {
        services.lifetime.didBecomeActive()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        services.lifetime.willResignActive()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        services.lifetime.didEnterBackground()
    }
}
