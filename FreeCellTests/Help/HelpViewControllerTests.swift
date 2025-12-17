@testable import TTFreeCell
import Testing
import UIKit
import WaitWhile

private struct HelpViewControllerTests {
    let subject = HelpViewController()
    let processor = MockReceiver<HelpAction>()
    let datasource: MockDatasource!
    let pageViewController = UIPageViewController()

    init() {
        subject.processor = processor
        datasource = MockDatasource(pageViewController: pageViewController, processor: processor)
        subject.datasource = datasource
    }

    @Test("pageViewController is correctly constructed")
    func pageViewControllerTest() {
        let subject = HelpViewController()
        let processor = MockReceiver<HelpAction>()
        subject.processor = processor
        let pageViewController = subject.pageViewController
        #expect(pageViewController.children.count == 1)
        #expect(pageViewController.navigationOrientation == .horizontal)
        #expect(pageViewController.transitionStyle == .scroll)
        #expect(pageViewController.spineLocation == UIPageViewController.SpineLocation.none)
    }

    @Test("datasource is correctly constructed")
    func datasourceConstruction() throws {
        let subject = HelpViewController()
        let processor = MockReceiver<HelpAction>()
        subject.processor = processor
        let datasource = try #require(subject.datasource as? HelpDatasource)
        #expect(datasource.processor === processor)
        #expect(datasource.pvc === subject.pageViewController)
    }

    @Test("viewDidLoad: does all the things")
    func viewDidLoad() async throws {
        subject.pageViewController = pageViewController
        subject.loadViewIfNeeded()
        #expect(subject.title == "Help")
        #expect(subject.view.backgroundColor?.resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .light)
        ) == UIColor(red: 1,  green: 1,  blue: 238.0/255.0, alpha: 1.0))
        #expect(subject.view.backgroundColor?.resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .dark)
        ) == UIColor.black)
        let undoItem = try #require(subject.navigationItem.leftBarButtonItem)
        #expect(undoItem.image == UIImage(systemName: "arrow.uturn.backward"))
        #expect(undoItem.target === subject)
        #expect(undoItem.action == #selector(subject.goBack))
        #expect(subject.navigationItem.leftItemsSupplementBackButton == true)
        let leftItem = try #require(subject.navigationItem.rightBarButtonItems?[1])
        #expect(leftItem.image == UIImage(systemName: "arrowshape.left"))
        #expect(leftItem.target === subject)
        #expect(leftItem.action == #selector(subject.goLeft))
        let rightItem = try #require(subject.navigationItem.rightBarButtonItems?[0])
        #expect(rightItem.image == UIImage(systemName: "arrowshape.right"))
        #expect(rightItem.target === subject)
        #expect(rightItem.action == #selector(subject.goRight))
        #expect(pageViewController.view.isDescendant(of: subject.view))
        #expect(pageViewController.dataSource === subject.datasource)
        #expect(pageViewController.delegate === subject.datasource)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.initialData])
    }

    @Test("viewWillAppear: if not being presented, does nothing")
    func viewWillAppearNotPresented() {
        let navigationController = UINavigationController(rootViewController: subject)
        makeWindow(viewController: navigationController)
        subject.loadViewIfNeeded()
        subject.viewWillAppear(false)
        #expect(subject.navigationItem.leftBarButtonItems?.count == 1)
        #expect(subject.navigationItem.leftBarButtonItem?.image == UIImage(systemName: "arrow.uturn.backward"))
    }

    @Test("viewWillAppear: if being presented, injects cancel left bar button item")
    func viewWillAppearPresented() {
        let viewController = UIViewController()
        makeWindow(viewController: viewController)
        let navigationController = UINavigationController(rootViewController: subject)
        viewController.present(navigationController, animated: false)
        subject.loadViewIfNeeded()
        subject.viewWillAppear(false)
        #expect(subject.navigationItem.leftBarButtonItems?.count == 3)
        #expect(subject.navigationItem.leftBarButtonItems?[2].image == UIImage(systemName: "arrow.uturn.backward"))
        #expect(subject.navigationItem.leftBarButtonItems?[1] == UIBarButtonItem.fixedSpace())
        #expect(subject.navigationItem.leftBarButtonItems?[0].target === subject)
        #expect(subject.navigationItem.leftBarButtonItems?[0].action == #selector(subject.doCancel))
    }

    @Test("viewDidAppear: turns off nav controller interactive pop gestures")
    func viewDidAppear() {
        let navigationController = UINavigationController(rootViewController: subject)
        subject.viewDidAppear(false)
        #expect(navigationController.interactivePopGestureRecognizer?.isEnabled == false)
        #expect(navigationController.interactiveContentPopGestureRecognizer?.isEnabled == false)
        #expect(navigationController.isModalInPresentation == true)
    }

    @Test("viewWillDisappear: turns on nav controller interactive pop gestures")
    func viewWillDisappear() {
        let navigationController = UINavigationController(rootViewController: subject)
        subject.viewWillDisappear(false)
        #expect(navigationController.interactivePopGestureRecognizer?.isEnabled == true)
        #expect(navigationController.interactiveContentPopGestureRecognizer?.isEnabled == true)
    }

    @Test("present: passes state on to datasource")
    func present() async {
        await subject.present(HelpState(helpType: .help))
        #expect(datasource.state == HelpState(helpType: .help))
    }

    @Test("present: enablement of left bar button item depends on undo stack")
    func presentLeftBarButtonItem() async {
        subject.loadViewIfNeeded()
        var state = HelpState(helpType: .help)
        await subject.present(state)
        #expect(subject.navigationItem.leftBarButtonItem?.isEnabled == false)
        state.undoStack = ["howdy"]
        await subject.present(state)
        #expect(subject.navigationItem.leftBarButtonItem?.isEnabled == true)
        state.undoStack = []
        await subject.present(state)
        #expect(subject.navigationItem.leftBarButtonItem?.isEnabled == false)
    }

    @Test("receive: passes effect on to datasource")
    func receive() async {
        await subject.receive(.navigate(to: "hello"))
        #expect(datasource.effect == .navigate(to: "hello"))
    }

    @Test("goLeft: sends .goLeft to processor")
    func goLeft() async {
        subject.goLeft()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.goLeft])
    }

    @Test("goRight: sends .goRight to processor")
    func goRight() async {
        subject.goRight()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.goRight])
    }

    @Test("goBack: sends .goBack to processor")
    func goBack() async {
        subject.goBack()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.goBack])
    }

    @Test("doCancel: sends .dismiss to processor")
    func cancel() async {
        subject.doCancel()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.dismiss])
    }
}

private final class MockDatasource: NSObject, PageViewControllerDatasourceType {
    typealias ProcessorActionType = HelpAction
    typealias EffectType = HelpEffect
    typealias DataType = String
    typealias StateType = HelpState

    var processor: (any Receiver<TTFreeCell.HelpAction>)?
    var data: [String]

    var methodsCalled = [String]()
    var state: HelpState?
    var effect: HelpEffect?

    init(pageViewController: UIPageViewController, processor: (any Receiver<HelpAction>)?) {
        self.data = []
    }

    func present(_ state: HelpState) async {
        methodsCalled.append(#function)
        self.state = state
    }
    
    func receive(_ effect: HelpEffect) async {
        methodsCalled.append(#function)
        self.effect = effect
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return nil
    }

}
