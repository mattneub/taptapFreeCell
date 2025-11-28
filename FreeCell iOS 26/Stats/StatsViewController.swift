import UIKit

final class StatsViewController: UITableViewController, ReceiverPresenter {
    weak var processor: (any Receiver<StatsAction>)?

    /// Our data source object. It is lazily created when we receive our first `present` call.
    lazy var datasource: any StatsDatasourceType<StatsEffect, StatsState> = StatsDatasource(
        tableView: tableView,
        processor: processor
    )

    lazy var recordLabel = UILabel().applying {
        $0.font = UIFont.systemFont(ofSize: 17)
        $0.textAlignment = .center
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }

    lazy var sortSegmentedControl = UISegmentedControl(items: ["Date", "Time", "Moves", "Won"]).applying { seg in
        seg.heightAnchor.constraint(equalToConstant: 22).isActive = true
        seg.isMomentary = true
        seg.selectedSegmentIndex = UISegmentedControl.noSegment
        seg.translatesAutoresizingMaskIntoConstraints = false
        seg.addAction(UIAction(handler: { [weak self] _ in
            self?.doSegmentedControl(seg)
        }), for: .valueChanged)
    }

    lazy var tableHeaderView = UIView().applying {
        $0.addSubview(recordLabel)
        NSLayoutConstraint.activate([
            $0.topAnchor.constraint(equalTo: recordLabel.topAnchor),
            $0.leadingAnchor.constraint(equalTo: recordLabel.leadingAnchor),
            $0.trailingAnchor.constraint(equalTo: recordLabel.trailingAnchor),
        ])
        $0.addSubview(sortSegmentedControl)
        sortSegmentedControl.topAnchor.constraint(equalTo: recordLabel.bottomAnchor, constant: 4).isActive = true
        NSLayoutConstraint.activate([
            $0.leadingAnchor.constraint(equalTo: sortSegmentedControl.leadingAnchor),
            $0.trailingAnchor.constraint(equalTo: sortSegmentedControl.trailingAnchor),
        ])
        let bottomConstraint = $0.bottomAnchor.constraint(equalTo: sortSegmentedControl.bottomAnchor, constant: 4)
        bottomConstraint.priority = UILayoutPriority(999)
        bottomConstraint.isActive = true
        $0.isHidden = true
    }

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
        title = "Statistics"
        tableView.backgroundView = spinnerContainer
        tableView.tableHeaderView = tableHeaderView
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

    override func viewWillLayoutSubviews() {
        tableHeaderView.bounds.size.height = 30 + 22 + 4 + 4
        sortSegmentedControl.setWidth(62, forSegmentAt: 3)
        sortSegmentedControl.setWidth((view.bounds.width - 62)/3.5 + 4, forSegmentAt: 0)
        super.viewWillLayoutSubviews()
    }

    func present(_ state: StatsState) async {
        let total = state.stats.count
        let won = state.stats.values.filter { $0.won }.count
        recordLabel.text = "Played \(total), Won \(won)"
        tableHeaderView.isHidden = false
        await datasource.present(state)
    }

    func receive(_ effect: StatsEffect) async {}

    func doSegmentedControl(_ seg: UISegmentedControl) {
        Task {
            await datasource.receive(.segmentSelected(seg.selectedSegmentIndex))
        }
    }
}
