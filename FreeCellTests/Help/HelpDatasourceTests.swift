@testable import TTFreeCell
import Testing
import UIKit
import WaitWhile

private struct HelpDatasourceTests {
    var subject: HelpDatasource!
    let processor = MockReceiver<HelpAction>()
    let pvc = MockPageViewController()

    init() {
        subject = HelpDatasource(pageViewController: pvc, processor: processor)
        subject.webViewViewControllerType = MockWebViewViewController.self
    }

    @Test("present: rules, sets data, creates first web view in page view controller according to state")
    func presentRules() async throws {
        let state = HelpState(helpType: .rules)
        await subject.present(state)
        #expect(subject.data == state.nextPrevsArray)
        let viewController = try #require(pvc.viewController as? MockWebViewViewController)
        #expect(viewController.methodsCalled == ["loadPage(name:)"])
        #expect(viewController.name == "rules")
        #expect(viewController.processor === processor)
        #expect(pvc.methodsCalled == ["setViewControllers(_:direction:animated:completion:)"])
        #expect(pvc.direction == .forward)
        #expect(pvc.animated == false)
        #expect(pvc.completion == nil)
    }

    @Test("present: help, sets data, creates first web view in page view controller according to state")
    func presentHelp() async throws {
        let state = HelpState(helpType: .help)
        await subject.present(state)
        #expect(subject.data == state.nextPrevsArray)
        let viewController = try #require(pvc.viewController as? MockWebViewViewController)
        #expect(viewController.methodsCalled == ["loadPage(name:)"])
        #expect(viewController.name == "taptap")
        #expect(viewController.processor === processor)
        #expect(pvc.methodsCalled == ["setViewControllers(_:direction:animated:completion:)"])
        #expect(pvc.direction == .forward)
        #expect(pvc.animated == false)
        #expect(pvc.completion == nil)
    }

    @Test("receive goLeft: navigates reverse to previous page")
    func goLeft() async throws {
        subject.data = HelpState(helpType: .rules).nextPrevsArray
        let initialViewController = MockWebViewViewController()
        initialViewController.currentPageName = "rules2"
        pvc.addChild(initialViewController)
        await subject.receive(.goLeft)
        let viewController = try #require(pvc.viewController as? MockWebViewViewController)
        #expect(viewController.methodsCalled == ["loadPage(name:)"])
        #expect(viewController.name == "rules")
        #expect(viewController.processor === processor)
        #expect(pvc.methodsCalled == ["setViewControllers(_:direction:animated:completion:)"])
        #expect(pvc.direction == .reverse)
        #expect(pvc.animated == true)
        #expect(pvc.completion == nil)
    }

    @Test("receive goLeft: does nothing if no previous page")
    func goLeftImpossible() async throws {
        subject.data = HelpState(helpType: .rules).nextPrevsArray
        let initialViewController = MockWebViewViewController()
        initialViewController.currentPageName = subject.data.first ?? "dummy"
        pvc.addChild(initialViewController)
        await subject.receive(.goLeft)
        #expect(pvc.viewController == nil)
        #expect(pvc.methodsCalled.isEmpty)
    }

    @Test("receive goRight: navigates forward to next page")
    func goRight() async throws {
        subject.data = HelpState(helpType: .rules).nextPrevsArray
        let initialViewController = MockWebViewViewController()
        initialViewController.currentPageName = "rules2"
        pvc.addChild(initialViewController)
        await subject.receive(.goRight)
        let viewController = try #require(pvc.viewController as? MockWebViewViewController)
        #expect(viewController.methodsCalled == ["loadPage(name:)"])
        #expect(viewController.name == "rules3")
        #expect(viewController.processor === processor)
        #expect(pvc.methodsCalled == ["setViewControllers(_:direction:animated:completion:)"])
        #expect(pvc.direction == .forward)
        #expect(pvc.animated == true)
        #expect(pvc.completion == nil)
    }

    @Test("receive goRight: does nothing if no next page")
    func goRightImpossible() async throws {
        subject.data = HelpState(helpType: .rules).nextPrevsArray
        let initialViewController = MockWebViewViewController()
        initialViewController.currentPageName = subject.data.last ?? "dummy"
        pvc.addChild(initialViewController)
        await subject.receive(.goRight)
        #expect(pvc.viewController == nil)
        #expect(pvc.methodsCalled.isEmpty)
    }

    @Test("navigate: navigates reverse if target is before source")
    func navigateLeft() async throws {
        subject.data = HelpState(helpType: .rules).nextPrevsArray
        let initialViewController = MockWebViewViewController()
        initialViewController.currentPageName = "rules2"
        pvc.addChild(initialViewController)
        await subject.receive(.navigate(to: "rules"))
        let viewController = try #require(pvc.viewController as? MockWebViewViewController)
        #expect(viewController.methodsCalled == ["loadPage(name:)"])
        #expect(viewController.name == "rules")
        #expect(viewController.processor === processor)
        #expect(pvc.methodsCalled == ["setViewControllers(_:direction:animated:completion:)"])
        #expect(pvc.direction == .reverse)
        #expect(pvc.animated == true)
        #expect(pvc.completion == nil)
    }

    @Test("navigate: navigates forward if target is after source")
    func navigateRight() async throws {
        subject.data = HelpState(helpType: .rules).nextPrevsArray
        let initialViewController = MockWebViewViewController()
        initialViewController.currentPageName = "rules2"
        pvc.addChild(initialViewController)
        await subject.receive(.navigate(to: "rules3"))
        let viewController = try #require(pvc.viewController as? MockWebViewViewController)
        #expect(viewController.methodsCalled == ["loadPage(name:)"])
        #expect(viewController.name == "rules3")
        #expect(viewController.processor === processor)
        #expect(pvc.methodsCalled == ["setViewControllers(_:direction:animated:completion:)"])
        #expect(pvc.direction == .forward)
        #expect(pvc.animated == true)
        #expect(pvc.completion == nil)
    }

    @Test("didFinishAnimating: sends userSwiped to processor")
    func didFinish() async {
        subject.pageViewController(pvc, didFinishAnimating: true, previousViewControllers: [UIViewController()], transitionCompleted: true)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.userSwiped])
    }
}

final class MockWebViewViewController: WebViewViewController {
    var methodsCalled = [String]()
    var name: String?

    override func loadPage(name: String) {
        methodsCalled.append(#function)
        self.name = name
    }
}

private final class MockPageViewController: UIPageViewController {
    var methodsCalled = [String]()
    var viewController: UIViewController?
    var direction: UIPageViewController.NavigationDirection?
    var animated: Bool?
    var completion: ((Bool) -> Void)?

    override func setViewControllers(_ viewControllers: [UIViewController]?, direction: UIPageViewController.NavigationDirection, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        methodsCalled.append(#function)
        self.viewController = viewControllers?.first
        self.direction = direction
        self.animated = animated
        self.completion = completion
    }
}
