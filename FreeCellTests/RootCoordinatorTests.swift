@testable import TTFreeCell
import Testing
import UIKit
import WaitWhile

private struct RootCoordinatorTests {
    let subject = RootCoordinator()

    @Test("createInterface: sets up root module")
    func createInterface() throws {
        let window = UIWindow()
        subject.createInterface(window: window)
        let processor = try #require(subject.gameProcessor as? GameProcessor)
        #expect(processor.coordinator === subject)
        let viewController = try #require(processor.presenter as? GameViewController)
        #expect(viewController.processor === processor)
        let navigationController = try #require(subject.rootViewController as? UINavigationController)
        #expect(navigationController.viewControllers.first === viewController)
        #expect(window.rootViewController === navigationController)
        #expect(navigationController.delegate === subject)
        #expect(window.backgroundColor == .systemBackground)
    }

    @Test("showAlert puts up the specified alert")
    func showAlert() async throws {
        let viewController = UIViewController()
        makeWindow(viewController: viewController)
        subject.rootViewController = viewController
        var result: String?
        Task {
            result = await subject.showAlert(title: "title", message: "message", buttonTitles: ["button1", "button2"])
        }
        await #while(viewController.presentedViewController == nil)
        let alert = try #require(viewController.presentedViewController as? UIAlertController)
        #expect(alert.title == "title")
        #expect(alert.message == "message")
        #expect(alert.actions[0].title == "button1")
        #expect(alert.actions[1].title == "button2")
        alert.tapButton(atIndex: 0)
        await #while(result == nil)
        #expect(result == "button1")
    }

    @Test("showStats constructs the stats module, pushes stats view controller")
    func showStats() async throws {
        let navigationController = UINavigationController()
        subject.rootViewController = navigationController
        let gameProcessor = GameProcessor()
        subject.gameProcessor = gameProcessor
        subject.showStats()
        let processor = try #require(subject.statsProcessor as? StatsProcessor)
        #expect(processor.coordinator === subject)
        #expect(processor.delegate === gameProcessor)
        let viewController = try #require(processor.presenter as? StatsViewController)
        #expect(viewController.processor === processor)
        #expect(navigationController.children.first == viewController)
    }

    @Test("popToGame: pops navigation controller back to root")
    func popToGame() async {
        let viewController = UIViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        subject.rootViewController = navigationController
        navigationController.delegate = subject // omit that at your peril!
        makeWindow(viewController: navigationController) // this too!
        navigationController.pushViewController(UIViewController(), animated: false)
        #expect(navigationController.children.count == 2)
        await(subject.popToGame())
        #expect(navigationController.children.count == 1)
        #expect(navigationController.children.first === viewController)
    }

    @Test("showMail: calls Mailer to get view controller, presents it")
    func showMail() {
        let mailer = MockMailer()
        mailer.viewControllerToReturn = UIViewController()
        services.mailer = mailer
        let viewController = UIViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        subject.rootViewController = navigationController
        makeWindow(viewController: navigationController)
        subject.showMail(message: "howdy")
        #expect(mailer.methodsCalled == ["mailViewController(message:)"])
        #expect(mailer.message == "howdy")
        #expect(navigationController.presentedViewController === mailer.viewControllerToReturn)
    }

    @Test("showPreview: calls Previewer to get view controller, pushes it")
    func showPreview() async {
        let stat = Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: Layout(), movesCount: 1, timeTaken: 1)
        let previewer = MockPreviewer()
        previewer.viewControllerToReturn = UIViewController()
        services.previewer = previewer
        let viewController = UIViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        subject.rootViewController = navigationController
        makeWindow(viewController: navigationController)
        await subject.showPreview(stat: stat)
        #expect(previewer.methodsCalled == ["viewController(for:)"])
        #expect(navigationController.topViewController === previewer.viewControllerToReturn)
    }

    @Test("showHelp: constructs module, pushes it")
    func showHelp() async throws {
        let navigationController = UINavigationController()
        subject.rootViewController = navigationController
        subject.showHelp(.help)
        let processor = try #require(subject.helpProcessor as? HelpProcessor)
        #expect(processor.coordinator === subject)
        #expect(processor.state.helpType == .help) // *
        let viewController = try #require(processor.presenter as? HelpViewController)
        #expect(viewController.processor === processor)
        #expect(navigationController.children.first == viewController)
    }

    @Test("showSafari: asks safari provider for view controller, presents it over current context")
    func showSafari() {
        let provider = MockSafariProvider()
        services.safariProvider = provider
        let viewController = UIViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        subject.rootViewController = navigationController
        makeWindow(viewController: navigationController)
        subject.showSafari(url: URL(string: "manny")!)
        #expect(provider.methodsCalled == ["provide(for:)"])
        #expect(navigationController.presentedViewController is MockSafariViewController)
    }

    @Test("showImportExport: constructs the module and presents it")
    func showImportExport() async throws {
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        let gameProcessor = GameProcessor()
        subject.gameProcessor = gameProcessor
        subject.showImportExport()
        let processor = try #require(subject.exportProcessor as? ExportProcessor)
        await #while(rootViewController.presentedViewController == nil)
        #expect(processor.coordinator === subject)
        #expect(processor.delegate === gameProcessor)
        let viewController = try #require(processor.presenter as? ExportViewController)
        #expect(viewController.processor === processor)
        #expect(rootViewController.presentedViewController === viewController)
    }

    @Test("dismiss: dismisses presented view controller")
    func dismiss() async throws {
        let rootViewController = UIViewController()
        subject.rootViewController = rootViewController
        let presentedViewController = UIViewController()
        rootViewController.present(presentedViewController, animated: false)
        await subject.dismiss()
        #expect(presentedViewController.presentingViewController == nil)
        #expect(rootViewController.presentedViewController == nil)
    }

    @Test("showMicrosoft: assembles module, presents as popover")
    func showMicrosoft() async throws {
        let rootViewController = UIViewController()
        makeWindow(viewController: rootViewController)
        subject.rootViewController = rootViewController
        let gameProcessor = GameProcessor()
        subject.gameProcessor = gameProcessor
        let source = UIView()
        subject.showMicrosoft(SourceItemWrapper(sourceItem: source))
        await #while(rootViewController.presentedViewController == nil)
        let processor = try #require(subject.microsoftProcessor as? MicrosoftProcessor)
        let viewController = try #require(processor.presenter as? MicrosoftViewController)
        #expect(processor.coordinator === subject)
        #expect(processor.delegate === gameProcessor)
        #expect(viewController.processor === processor)
        #expect(viewController.modalPresentationStyle == .popover)
        #expect(viewController.presentationController?.delegate === viewController)
        #expect(viewController.popoverPresentationController?.sourceItem === source)
        #expect(rootViewController.presentedViewController === viewController)
    }

    @Test("showPrefs: assembles modules, pushes it")
    func showPrefs() throws {
        let gameProcessor = GameProcessor()
        subject.gameProcessor = gameProcessor
        let navigationController = UINavigationController()
        subject.rootViewController = navigationController
        let prefsState = PrefsState(prefs: [Pref(key: .automoveToFoundations, value: true)], speed: .glacial)
        subject.showPrefs(prefsState)
        let processor = try #require(subject.prefsProcessor as? PrefsProcessor)
        #expect(processor.coordinator === subject)
        #expect(processor.state == prefsState)
        #expect(processor.delegate === gameProcessor)
        let viewController = try #require(processor.presenter as? PrefsViewController)
        #expect(viewController.processor === processor)
        #expect(navigationController.children.first == viewController)
    }
}
