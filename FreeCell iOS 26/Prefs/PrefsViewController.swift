import UIKit

final class PrefsViewController: UITableViewController, ReceiverPresenter {
    weak var processor: (any Receiver<PrefsAction>)?

    /// Our data source object. It is lazily created when we receive our first `present` call.
    lazy var datasource: any PrefsDatasourceType<PrefsEffect, PrefsState> = PrefsDatasource(
        tableView: tableView,
        processor: processor
    )

    convenience init() {
        self.init(style: .insetGrouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            await processor?.receive(.initialData)
        }
    }

    func present(_ state: PrefsState) async {
        await datasource.present(state)
    }

    func receive(_ effect: PrefsEffect) async {
        await datasource.receive(effect)
    }

    /// Called as a nil-targeted action from PrefSwitch in cell.
    @objc func prefSwitchChanged(_ sender: Any) {
        guard let sender = sender as? PrefSwitch else { return }
        guard let prefKey = sender.prefKey else { return }
        Task {
            await processor?.receive(.prefChanged(prefKey, value: sender.isOn))
        }
    }

    /// Called as a nil-targeted action from UISegmentedControl in cell.
    @objc func segmentedControlChanged(_ sender: Any) {
        guard let sender = sender as? UISegmentedControl else { return }
        Task {
            await processor?.receive(.speedChanged(index: sender.selectedSegmentIndex))
        }
    }
}
