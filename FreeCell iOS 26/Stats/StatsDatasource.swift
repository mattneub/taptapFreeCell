import UIKit

/// Protocol describing the view controller's interaction with the datasource, so we can
/// mock it for testing.
protocol StatsDatasourceType<State>: Presenter, UITableViewDelegate {
    associatedtype State
}

/// Table view data source and delegate for the view controller's table view.
final class StatsDatasource: NSObject, StatsDatasourceType {
    typealias State = StatsState

    /// Processor to whom we can send action messages.
    weak var processor: (any Receiver<StatsAction>)?

    /// Weak reference to the table view.
    weak var tableView: UITableView?

    /// Reuse identifier for the table view cells we will be creating.
    private let reuseIdentifier = "reuseIdentifier"

    init(tableView: UITableView, processor: (any Receiver<StatsAction>)?) {
        self.tableView = tableView
        self.processor = processor
        super.init()
        // We're going to use a diffable data source. Register the cell type, make the
        // diffable data source, and set the table view's dataSource and delegate.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        datasource = createDataSource(tableView: tableView)
        tableView.dataSource = datasource
        tableView.delegate = self
        tableView.estimatedRowHeight = 50
    }

    func present(_ state: StatsState) async {
        await configureData(data: state.stats)
    }

    var data = StatsDictionary()

    /// Type alias for the type of the data source, for convenience.
    typealias DatasourceType = UITableViewDiffableDataSource<String, String>

    /// Retain the diffable data source.
    var datasource: DatasourceType!

    func createDataSource(tableView: UITableView) -> DatasourceType {
        let datasource = DatasourceType(
            tableView: tableView
        ) { [unowned self] tableView, indexPath, identifier in
            return cellProvider(tableView, indexPath, identifier)
        }
        return datasource
    }

    func configureData(data: StatsDictionary) async {
        // We only need to do this once.
        var snapshot = NSDiffableDataSourceSnapshot<String, String>()
        guard snapshot.itemIdentifiers.isEmpty else {
            return
        }
        self.data = data
        snapshot.appendSections(["dummy"])
        snapshot.appendItems(Array(data)
            .sorted {
                $0.value.dateFinished > $1.value.dateFinished
            }.map {
                $0.key
            }
        )
        // TODO: but this is not _real_ sorting, it's just so I can see something useful for now
        await datasource?.apply(snapshot, animatingDifferences: false)
    }

    func cellProvider(_ tableView: UITableView, _ indexPath: IndexPath, _ identifier: String) -> UITableViewCell? {
        guard let stat = data[identifier] else {
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let contentConfiguration = StatCellContentConfiguration(stat: stat)
        cell.contentConfiguration = contentConfiguration
        return cell
    }

}
