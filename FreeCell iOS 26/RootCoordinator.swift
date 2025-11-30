import UIKit

/// Public face of the root coordinator, so we can mock it for testing.
protocol RootCoordinatorType: AnyObject {
    func createInterface(window: UIWindow)
    func showAlert(title: String?, message: String?, buttonTitles: [String]) async -> String?
    func showStats()
    func popToGame() async
}

/// Object that constructs modules and manipulates view controllers.
final class RootCoordinator: NSObject, RootCoordinatorType {
    weak var rootViewController: UIViewController?

    var gameProcessor: (any Processor<GameAction, GameState, GameEffect>)?
    var statsProcessor: (any Processor<StatsAction, StatsState, StatsEffect>)?

    func createInterface(window: UIWindow) {
        let processor = GameProcessor()
        self.gameProcessor = processor
        let viewController = GameViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.delegate = self // for `popToGame`
        self.rootViewController = navigationController
        processor.presenter = viewController
        processor.coordinator = self
        viewController.processor = processor
        window.rootViewController = navigationController
        window.backgroundColor = .systemBackground
    }

    /// Secondary reference to the continuation on `showAlert`, so we can resume it from tests.
    var alertContinuation: CheckedContinuation<String?, Never>?

    func showAlert(title: String?, message: String?, buttonTitles: [String]) async -> String? {
        guard !(title == nil && message == nil) else { return nil }
        return await withCheckedContinuation { continuation in
            self.alertContinuation = continuation
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            for title in buttonTitles {
                alert.addAction(UIAlertAction(title: title, style: .default, handler: { action in
                    continuation.resume(returning: action.title)
                    self.alertContinuation = nil
                }))
            }
            rootViewController?.present(alert, animated: unlessTesting(true))
        }
    }

    func showStats() {
        let processor = StatsProcessor()
        self.statsProcessor = processor
        let viewController = StatsViewController()
        processor.presenter = viewController
        processor.coordinator = self
        processor.delegate = gameProcessor as? any StatsDelegate
        viewController.processor = processor
        (rootViewController as? UINavigationController)?.pushViewController(viewController, animated: unlessTesting(true))
    }

    var animationContinuation: CheckedContinuation<Void, Never>?

    func popToGame() async {
        await withCheckedContinuation { [weak self] continuation in
            self?.animationContinuation = continuation
            (self?.rootViewController as? UINavigationController)?.popToRootViewController(animated: unlessTesting(true))
        }
    }

}

extension RootCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // in case async `popToGame` was called (and no harm done otherwise)
        animationContinuation?.resume(returning: ())
        animationContinuation = nil
    }
}
