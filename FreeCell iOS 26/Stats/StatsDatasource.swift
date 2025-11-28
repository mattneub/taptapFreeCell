import UIKit

/// Protocol describing the view controller's interaction with the datasource, so we can
/// mock it for testing.
protocol StatsDatasourceType<Received, State>: ReceiverPresenter, UITableViewDelegate {
    associatedtype State
    associatedtype Received
}

/// Table view data source and delegate for the view controller's table view.
final class StatsDatasource: NSObject, StatsDatasourceType {
    typealias State = StatsState
    typealias Received = StatsEffect

    /// Processor to whom we can send action messages.
    weak var processor: (any Receiver<StatsAction>)?

    /// Weak reference to the table view.
    weak var tableView: UITableView?

    /// Reuse identifier for the table view cells we will be creating.
    private let reuseIdentifier = "reuseIdentifier"

    /// Currently selected index of the sort segmented control.
    var selectedIndex = 0

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

    func receive(_ effect: StatsEffect) async {
        switch effect {
        case .segmentSelected(let index):
            await sortAndUpdateTable(index: index)
        }
    }

    /// Our underlying data. It is a dictionary, so we can do fast lookup of a Stat by layout key.
    var data = StatsDictionary()

    /// The data fed to the table view. It is an array, so we can order it and thus order the table.
    var sortedData = Array(StatsDictionary())

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
        self.sortedData = Array(data)
        baseSort()
        snapshot.appendSections(["dummy"])
        snapshot.appendItems(sortedData.map { $0.key })
        await datasource?.apply(snapshot, animatingDifferences: false)
    }

    func updateTable() async {
        var snapshot = datasource.snapshot()
        snapshot.deleteAllItems()
        snapshot.appendSections(["dummy"])
        snapshot.appendItems(sortedData.map { $0.key })
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

    func baseSort() {
        sortedData = sortedData.sorted { $0.value.dateFinished > $1.value.dateFinished }
    }

    func sortAndUpdateTable(index: Int) async {
        if index == selectedIndex {
            sortedData = sortedData.reversed()
        } else {
            baseSort()
            switch index {
            case 0: break
            case 1:
                sortedData = sortedData.sorted { $0.value.timeTaken < $1.value.timeTaken }
            case 2:
                sortedData = sortedData.sorted { $0.value.movesCount < $1.value.movesCount }
            case 3:
                sortedData = sortedData.sorted { !$0.value.won && $1.value.won }
            default: break
            }
            selectedIndex = index
        }
        await updateTable()
    }

}
