@testable import TTFreeCell
import Testing
import UIKit
import WaitWhile

struct RootCoordinatorTests {
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
}
