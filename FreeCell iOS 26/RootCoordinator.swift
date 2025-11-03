import UIKit

/// Public face of the root coordinator, so we can mock it for testing.
protocol RootCoordinatorType: AnyObject {
    func createInterface(window: UIWindow)
}

/// Object that constructs modules and manipulates view controllers.
final class RootCoordinator: RootCoordinatorType {
    weak var rootViewController: UIViewController?

    var gameProcessor: (any Processor<GameAction, GameState, GameEffect>)?

    func createInterface(window: UIWindow) {
        let processor = GameProcessor()
        self.gameProcessor = processor
        let viewController = GameViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        self.rootViewController = navigationController
        processor.presenter = viewController
        processor.coordinator = self
        viewController.processor = processor
        window.rootViewController = navigationController
        window.backgroundColor = .systemBackground
    }

}
