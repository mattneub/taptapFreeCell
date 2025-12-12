import UIKit

/// Public face of the root coordinator, so we can mock it for testing.
protocol RootCoordinatorType: AnyObject {
    func createInterface(window: UIWindow)
    func showAlert(title: String?, message: String?, buttonTitles: [String]) async -> String?
    func showStats()
    func popToGame() async
    func showMail(message: String)
    func showPreview(stat: Stat) async
    func showHelp(_: HelpState.HelpType)
    func showSafari(url: URL)
    func showImportExport()
    func dismiss() async
    func showMicrosoft(_: SourceItemWrapper)
    func showPrefs()
}

/// Object that constructs modules and manipulates view controllers.
final class RootCoordinator: NSObject, RootCoordinatorType {
    weak var rootViewController: UIViewController?

    var gameProcessor: (any Processor<GameAction, GameState, GameEffect>)?
    var statsProcessor: (any Processor<StatsAction, StatsState, StatsEffect>)?
    var helpProcessor: (any Processor<HelpAction, HelpState, HelpEffect>)?
    var exportProcessor: (any Processor<ExportAction, ExportState, Void>)?
    var microsoftProcessor: (any Processor<MicrosoftAction, MicrosoftState, Void>)?
    var prefsProcessor: (any Processor<PrefsAction, PrefsState, Void>)?

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

    func showMail(message: String) {
        if let viewController = services.mailer.mailViewController(message: message) {
            rootViewController?.present(viewController, animated: unlessTesting(true))
        }
    }

    func showPreview(stat: Stat) async {
        if let viewController = await services.previewer.viewController(for: stat) {
            (rootViewController as? UINavigationController)?.pushViewController(viewController, animated: true)
        }
    }

    func showHelp(_ helpType: HelpState.HelpType) {
        let processor = HelpProcessor()
        processor.state = HelpState(helpType: helpType)
        self.helpProcessor = processor
        let viewController = HelpViewController()
        processor.presenter = viewController
        processor.coordinator = self
        viewController.processor = processor
        (rootViewController as? UINavigationController)?.pushViewController(viewController, animated: unlessTesting(true))
    }

    func showSafari(url: URL) {
        let viewController = services.safariProvider.provide(for: url)
        viewController.modalPresentationStyle = .overCurrentContext
        rootViewController?.present(viewController, animated: unlessTesting(true))
    }

    func showImportExport() {
        let processor = ExportProcessor()
        self.exportProcessor = processor
        let viewController = ExportViewController()
        processor.presenter = viewController
        processor.coordinator = self
        processor.delegate = gameProcessor as? any ExportDelegate
        viewController.processor = processor
        rootViewController?.present(viewController, animated: unlessTesting(true))
    }

    func dismiss() async {
        await withCheckedContinuation { [weak self] continuation in
            self?.rootViewController?.dismiss(animated: unlessTesting(true)) {
                continuation.resume(returning: ())
            }
        }
    }

    func showMicrosoft(_ wrapper: SourceItemWrapper) {
        let processor = MicrosoftProcessor()
        self.microsoftProcessor = processor
        let viewController = MicrosoftViewController(nibName: "Microsoft", bundle: nil)
        processor.presenter = viewController
        processor.coordinator = self
        processor.delegate = gameProcessor as? any MicrosoftDelegate
        viewController.processor = processor
        viewController.modalPresentationStyle = .popover
        viewController.presentationController?.delegate = viewController
        viewController.popoverPresentationController?.sourceItem = wrapper.sourceItem
        rootViewController?.present(viewController, animated: unlessTesting(true))
    }

    func showPrefs() {
        let processor = PrefsProcessor()
        self.prefsProcessor = processor
        let viewController = PrefsViewController()
        processor.presenter = viewController
        processor.coordinator = self
        viewController.processor = processor
        (rootViewController as? UINavigationController)?.pushViewController(viewController, animated: unlessTesting(true))
    }
}

extension RootCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // in case async `popToGame` was called (and no harm done otherwise)
        animationContinuation?.resume(returning: ())
        animationContinuation = nil
    }
}
