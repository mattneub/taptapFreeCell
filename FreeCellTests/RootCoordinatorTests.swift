@testable import FreeCell
import Testing
import UIKit

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
}
