import UIKit

/// Public face of the root coordinator, so we can mock it for testing.
protocol RootCoordinatorType: AnyObject {
    func createInterface(window: UIWindow)
    func showAlert(title: String?, message: String?, buttonTitles: [String]) async -> String?
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


}
