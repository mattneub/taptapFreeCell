import UIKit

final class HelpViewController: UIViewController, ReceiverPresenter {
    weak var processor: (any Receiver<HelpAction>)?

    /// Page view controller displaying web views.
    lazy var pageViewController: UIPageViewController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal,
        options: nil
    ).applying {
        // a page view controller should always contain _some_ view controller
        $0.setViewControllers([UIViewController()], direction: .forward, animated: false, completion: nil)
    }

    /// Our data source delegate object.
    lazy var datasource: any PageViewControllerDatasourceType<HelpAction, HelpEffect, HelpState, String> = HelpDatasource(
        pageViewController: pageViewController,
        processor: processor
    )

    /// "Go back" bar button item, factored out so we can enable and disable it.
    lazy var goBackItem = UIBarButtonItem(
        title: nil,
        image: UIImage(systemName: "arrow.uturn.backward"),
        target: self,
        action: #selector(goBack)
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Help"
        view.backgroundColor = UIColor {traits in
            switch traits.userInterfaceStyle {
            case .dark: .black
            case .light: UIColor(red: 1,  green: 1,  blue: 238.0/255.0, alpha: 1.0)
            case .unspecified: UIColor(red: 1,  green: 1,  blue: 238.0/255.0, alpha: 1.0)
            @unknown default: UIColor(red: 1,  green: 1,  blue: 238.0/255.0, alpha: 1.0)
            }
        }
        navigationItem.leftBarButtonItems = [goBackItem]
        navigationItem.leftItemsSupplementBackButton = true
        let leftItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "arrowshape.left"), target: self, action: #selector(goLeft))
        let rightItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "arrowshape.right"), target: self, action: #selector(goRight))
        navigationItem.rightBarButtonItems = [rightItem, leftItem]

        // Page view controller and its view.
        if let pageView = pageViewController.view {
            addChild(pageViewController) // dance
            pageView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(pageView)
            NSLayoutConstraint.activate([
                pageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                pageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                pageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                pageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
            pageViewController.didMove(toParent: self) // dance
            pageViewController.dataSource = datasource
            pageViewController.delegate = datasource
        }

        Task {
            await processor?.receive(.initialData)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if navigationController?.isBeingPresented ?? false {
            if navigationItem.leftBarButtonItems?.count == 1 {
                let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(doCancel))
                navigationItem.leftBarButtonItems?.insert(cancelButton, at: 0)
                navigationItem.leftBarButtonItems?.insert(UIBarButtonItem.fixedSpace(), at: 1)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        navigationController?.interactiveContentPopGestureRecognizer?.isEnabled = false
        navigationController?.isModalInPresentation = true // prevent swipe down to dismiss
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactiveContentPopGestureRecognizer?.isEnabled = true
    }

    func present(_ state: HelpState) async {
        await datasource.present(state)
        goBackItem.isEnabled = !state.undoStack.isEmpty
    }

    func receive(_ effect: HelpEffect) async {
        await datasource.receive(effect)
    }

    @objc func goBack() {
        Task {
            await processor?.receive(.goBack)
        }
    }

    @objc func goLeft() {
        Task {
            await processor?.receive(.goLeft)
        }
    }

    @objc func goRight() {
        Task {
            await processor?.receive(.goRight)
        }
    }

    @objc func doCancel() {
        Task {
            await processor?.receive(.dismiss)
        }
    }
}
