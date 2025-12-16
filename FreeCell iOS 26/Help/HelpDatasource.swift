import UIKit

/// Class whose instance acts as the page view controller data source and delegate for the page
/// view controller in the help view controller.
final class HelpDatasource: NSObject, PageViewControllerDatasourceType {
    typealias ProcessorActionType = HelpAction
    typealias EffectType = HelpEffect
    typealias DataType = String
    typealias StateType = HelpState

    weak var processor: (any Receiver<HelpAction>)?

    weak var pvc: UIPageViewController?

    /// The type of the web view view controller, so we can inject a mock for testing.
    var webViewViewControllerType: WebViewViewController.Type = WebViewViewController.self

    init(pageViewController: UIPageViewController, processor: (any Receiver<HelpAction>)?) {
        self.processor = processor
        self.pvc = pageViewController
    }
    
    var data = [String]()

    func present(_ state: HelpState) async {
        configure(data: state.nextPrevsArray, initialIndex: state.initialIndex)
    }

    var configured = false

    /// Called from `present`, and runs only once.
    func configure(data: [String], initialIndex: Int) {
        guard !configured else {
            return
        }
        configured = true
        self.data = data
        let viewController = webViewViewControllerType.init()
        viewController.processor = processor
        viewController.loadPage(name: data[initialIndex])
        pvc?.setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
    }

    func receive(_ effect: HelpEffect) async {
        switch effect {
        case .goLeft:
            if let pvc {
                if let currentViewController = pvc.viewControllers?[0] {
                    if let viewController = pageViewController(pvc, viewControllerBefore: currentViewController) {
                        pvc.setViewControllers([viewController], direction: .reverse, animated: true, completion: nil)
                    }
                }
            }
        case .goRight:
            if let pvc {
                if let currentViewController = pvc.viewControllers?[0] {
                    if let viewController = pageViewController(pvc, viewControllerAfter: currentViewController) {
                        pvc.setViewControllers([viewController], direction: .forward, animated: true, completion: nil)
                    }
                }
            }
        case .navigate(let targetPageName):
            guard let viewController = pvc?.viewControllers?[0] as? WebViewViewController else { return }
            guard let sourceIndex = data.firstIndex(of: viewController.currentPageName) else { return }
            guard let targetIndex = data.firstIndex(of: targetPageName) else { return }
            let direction: UIPageViewController.NavigationDirection = sourceIndex < targetIndex ? .forward : .reverse
            let webViewViewController = webViewViewControllerType.init()
            webViewViewController.processor = processor
            webViewViewController.loadPage(name: targetPageName)
            pvc?.setViewControllers([webViewViewController], direction: direction, animated: true, completion: nil)
        }
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let viewController = viewController as? WebViewViewController else { return nil }
        guard let index = data.firstIndex(of: viewController.currentPageName) else { return nil }
        guard index > 0 else { return nil }
        let webViewViewController = webViewViewControllerType.init()
        webViewViewController.processor = processor
        webViewViewController.loadPage(name: data[index - 1])
        return webViewViewController
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let viewController = viewController as? WebViewViewController else { return nil }
        guard let index = data.firstIndex(of: viewController.currentPageName) else { return nil }
        guard index < data.count - 1 else { return nil }
        let webViewViewController = webViewViewControllerType.init()
        webViewViewController.processor = processor
        webViewViewController.loadPage(name: data[index + 1])
        return webViewViewController
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        Task {
            await processor?.receive(.userSwiped)
        }
    }
}
