import UIKit

final class StatsViewController: UITableViewController, ReceiverPresenter {
    weak var processor: (any Receiver<StatsAction>)?

    /// Our data source object. It is lazily created when we receive our first `present` call.
    lazy var datasource: any StatsDatasourceType<StatsState> = StatsDatasource(
        tableView: tableView,
        processor: processor
    )

    lazy var spinner = UIActivityIndicatorView(style: .large).applying {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.hidesWhenStopped = true
    }

    lazy var spinnerContainer = UIView().applying {
        $0.addSubview(spinner)
        $0.centerXAnchor.constraint(equalTo: spinner.centerXAnchor).isActive = true
        $0.centerYAnchor.constraint(equalTo: spinner.centerYAnchor).isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundView = spinnerContainer
        spinner.startAnimating()
    }

    var didInitialData = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didInitialData {
            Task {
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.25))
                }
                await processor?.receive(.initialData)
                didInitialData = true
                spinner.stopAnimating()
            }
        }
    }

    func present(_ state: StatsState) async {
        await datasource.present(state)
    }

    func receive(_ effect: StatsEffect) async {}
}
