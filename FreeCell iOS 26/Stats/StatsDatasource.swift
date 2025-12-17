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

    /// Current sort type. We do not bother to state whether this is a reverse sort.
    var sort: StatsSorting = .date

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
        case .delete(let row):
            sortedData.remove(at: row)
            await updateTable()
            // no need to remove anything from `data`! it's just a lookup table, it's not the
            // source for the table display
        case .sort(let sort):
            await sortAndUpdateTable(sort: sort)
        case .totalChanged:
            break // handled by view controller
        case .toggleMicrosofts:
            await toggleMicrosofts(sort: .date) // user tapped Numbered button, so resort to base sort
        }
    }

    /// Our underlying data. It is a dictionary, so we can do fast lookup of a Stat by layout key.
    var data = StatsDictionary()

    /// The data fed to the table view. It is an array of key-value pairs,
    /// so we can order it by value and thus order the table by key. Clever, eh?
    var sortedData = [Dictionary<String, Stat>.Element]()

    /// The unfiltered version of `sortedData`. If it is `nil`, we are not filtering, and vice
    /// versa.
    var unfilteredData: [Dictionary<String, Stat>.Element]?

    /// Type alias for the type of the data source, for convenience.
    typealias DatasourceType = UITableViewDiffableDataSource<String, String>

    /// Retain the diffable data source.
    var datasource: DatasourceType!

    /// Create the data source for the table view. Done just once, at `init` time.
    func createDataSource(tableView: UITableView) -> DatasourceType {
        let datasource = DatasourceType(
            tableView: tableView
        ) { [unowned self] tableView, indexPath, identifier in
            return cellProvider(tableView, indexPath, identifier)
        }
        return datasource
    }

    /// The data have arrived for the first time. Create the properties to hold the data
    /// and update the table. Done just once, at `present` time.
    func configureData(data: StatsDictionary) async {
        // We only need to do this once.
        let snapshot = NSDiffableDataSourceSnapshot<String, String>()
        guard snapshot.itemIdentifiers.isEmpty else {
            return
        }
        self.data = data
        self.sortedData = Array(data)
        baseSort()
        await updateTable()
    }

    /// Bottleneck routine, to be run every time the data changes by sorting or filtering. It is
    /// assumed that `sortedData` contains the data to be displayed. Display that data, and let
    /// the processor know the current totals.
    func updateTable(animating: Bool = false) async {
        var snapshot = datasource.snapshot()
        snapshot.deleteAllItems()
        snapshot.appendSections(["dummy"])
        snapshot.appendItems(sortedData.map { $0.key })
        await datasource?.apply(snapshot, animatingDifferences: animating)
        let total = sortedData.count
        let won = sortedData.filter { $0.value.won }.count
        await processor?.receive(.totalChanged(total: total, won: won))
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

    /// The fallback order, and effectively underlying all others, is date, newest first.
    func baseSort() {
        sort = .date
        sortedData = sortedData.sorted { $0.value.dateFinished > $1.value.dateFinished }
    }
    
    /// Sort the table as instructed.
    /// - Parameters:
    ///   - sort: The sort order. This must _never_ be `.microsoft`!
    func sortAndUpdateTable(sort: StatsSorting) async {
        guard unfilteredData == nil else { // we are filtered, pass this on to the unfiltering method
            await toggleMicrosofts(sort: sort)
            return
        }
        if sort == self.sort { // we are already sorted this way, so just reverse it and stop
            sortedData = sortedData.reversed()
        } else {
            baseSort()
            switch sort {
            case .date: break
            case .time:
                sortedData = sortedData.sorted { $0.value.timeTaken < $1.value.timeTaken }
            case .moves:
                sortedData = sortedData.sorted { $0.value.movesCount < $1.value.movesCount }
            case .won:
                sortedData = sortedData.sorted { !$0.value.won && $1.value.won }
            case .microsoft:
                break // shouldn't happen
            }
            self.sort = sort
        }
        await updateTable()
    }

    func toggleMicrosofts(sort: StatsSorting) async {
        if let unfilteredData { // we are filtered; unfilter, and sort as instructed
            sortedData = unfilteredData
            self.unfilteredData = nil
            await sortAndUpdateTable(sort: sort)
        } else {
            unfilteredData = sortedData
            sortedData = sortedData
                .filter { $0.value.microsoftDealNumber != nil }
                .sorted { $0.value.microsoftDealNumber ?? 0 < $1.value.microsoftDealNumber ?? 0 }
            self.sort = .microsoft // so that when we come _out_ of filtering, we do not reverse
            await updateTable()
        }
    }
}

extension StatsDatasource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !sortedData[indexPath.row].value.won
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Task {
            await processor?.receive(.resume(key: sortedData[indexPath.row].key))
            tableView.selectRow(at: nil, animated: false, scrollPosition: .none)
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard unfilteredData == nil else { // no swiping while we're filtered
            return nil
        }
        let deleteAction = MyUIContextualAction(myStyle: .destructive, title: "Delete") { [weak self] (action, view, completion) in
            guard let self else { return completion(false) }
            let stat = sortedData[indexPath.row].key
            sortedData.remove(at: indexPath.row)
            Task {
                await updateTable(animating: true)
                await processor?.receive(.delete(key: stat))
                completion(true) // looks great and the runtime is not complaining so what the heck
            }
        }
        let exportAction = MyUIContextualAction(myStyle: .normal, title: "Export") { [weak self] (action, view, completion) in
            guard let self else { return completion(false) }
            let stat = sortedData[indexPath.row].value
            Task {
                await processor?.receive(.mail(stat: stat))
                completion(true)
            }
        }
        exportAction.backgroundColor = .systemGreen
        let previewAction = MyUIContextualAction(myStyle: .normal, title: "View") { [weak self] (action, view, completion) in
            guard let self else { return completion(false) }
            let stat = sortedData[indexPath.row].value
            let cell = tableView.cellForRow(at: indexPath)
            Task {
                await processor?.receive(.showSnapshot(stat: stat, source: cell))
                completion(true)
            }
        }
        previewAction.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [deleteAction, exportAction, previewAction]).applying {
            $0.performsFirstActionWithFullSwipe = false
        }
    }
}
