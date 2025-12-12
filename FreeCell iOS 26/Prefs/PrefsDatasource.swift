import UIKit

/// Protocol describing the view controller's interaction with the datasource, so we can
/// mock it for testing.
protocol PrefsDatasourceType<Received, State>: ReceiverPresenter, UITableViewDelegate {
    associatedtype State
    associatedtype Received
}

/// Table view data source and delegate for the view controller's table view.
final class PrefsDatasource: NSObject, PrefsDatasourceType {
    typealias State = PrefsState
    typealias Received = Void

    weak var tableView: UITableView?

    weak var processor: (any Receiver<PrefsAction>)?

    init(tableView: UITableView, processor: (any Receiver<PrefsAction>)?) {
        self.tableView = tableView
        self.processor = processor
    }

    func present(_ state: PrefsState) async {
        
    }
}
