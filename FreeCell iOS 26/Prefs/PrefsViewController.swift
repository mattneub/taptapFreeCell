import UIKit

final class PrefsViewController: UITableViewController, ReceiverPresenter {
    weak var processor: (any Processor<PrefsAction, PrefsState, Void>)?

    /// Our data source object. It is lazily created when we receive our first `present` call.
    lazy var datasource: any PrefsDatasourceType<Void, PrefsState> = PrefsDatasource(
        tableView: tableView,
        processor: processor
    )

    convenience init() {
        self.init(style: .grouped)
    }

    

    func present(_ state: PrefsState) async {}
}
