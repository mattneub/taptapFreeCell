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
    typealias Received = PrefsEffect

    weak var tableView: UITableView?

    /// Reuse identifiers for the table view cells we will be creating. There are two,
    /// because we have two sections.
    private let reuseIdentifier0 = "reuseIdentifier0"
    private let reuseIdentifier1 = "reuseIdentifier1"

    weak var processor: (any Receiver<PrefsAction>)?

    init(tableView: UITableView, processor: (any Receiver<PrefsAction>)?) {
        self.tableView = tableView
        self.processor = processor
        super.init()
        // We're going to use a diffable data source. Register the cell types, make the
        // diffable data source, and set the table view's dataSource and delegate.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier0)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier1)
        datasource = createDataSource(tableView: tableView)
        tableView.dataSource = datasource
        tableView.delegate = self
        tableView.rowHeight = 52
        tableView.allowsSelection = false
        tableView.sectionHeaderHeight = 0 // trust me on this one
    }

    func present(_ state: PrefsState) async {
        self.speed = state.speed
        await configureData(data: state.prefs)
    }

    func receive(_ effect: PrefsEffect) async {
        switch effect {
        case .prefChanged(let prefKey, let value):
            let pref = Pref(key: prefKey, value: value)
            data[prefKey] = pref
            updateTable(for: pref)
        case .speedChanged(let index):
            let speed = GameState.AnimationSpeed.allCases[index]
            self.speed = speed
            updateTable(for: speed)
        }
    }

    /// Type alias for the type of the data source, for convenience.
    typealias DatasourceType = PrefsDiffableDataSource

    /// Retain the diffable data source.
    var datasource: DatasourceType!

    /// The prefs data. The table is effectively static, so the datasource maintains the correct
    /// order once it has been initially configured; thus, we do not need ordered data
    /// for anything, and the data here is kept as a dictionary for rapid lookup.
    var data = [PrefKey: Pref]()

    /// The speed data.
    var speed = GameState.AnimationSpeed.noAnimation

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
    func configureData(data: [Pref]) async {
        // We only need to do this once.
        var snapshot = NSDiffableDataSourceSnapshot<String, ItemWrapper>()
        guard snapshot.itemIdentifiers.isEmpty else {
            return
        }
        for pref in data {
            self.data[pref.key] = pref
        }
        snapshot.appendSections(["dummy"])
        snapshot.appendItems(data.map(\.key).map { ItemWrapper.pref($0) })
        snapshot.appendSections(["Card Animation Speed"])
        snapshot.appendItems([ItemWrapper.speed])
        await datasource.apply(snapshot, animatingDifferences: false)
    }

    func cellProvider(_ tableView: UITableView, _ indexPath: IndexPath, _ identifier: ItemWrapper) -> UITableViewCell? {
        switch identifier {
        case .pref(let prefKey):
            guard let pref = data[prefKey] else {
                return UITableViewCell()
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier0, for: indexPath)
            let contentConfiguration = PrefCellContentConfiguration(pref: pref)
            cell.contentConfiguration = contentConfiguration
            return cell
        case .speed:
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier1, for: indexPath)
            let contentConfiguration = SpeedCellContentConfiguration(speed: self.speed)
            cell.contentConfiguration = contentConfiguration
            return cell
        }
    }

    /// If a pref value changes, no need to reload the table view; just apply the configuration
    /// directly to the cell.
    func updateTable(for pref: Pref) {
        if let indexPath = datasource.indexPath(for: ItemWrapper.pref(pref.key)) {
            if let cell = tableView?.cellForRow(at: indexPath) {
                cell.contentConfiguration = PrefCellContentConfiguration(pref: pref)
            }
        }
    }

    /// If the speed value changes, no need to reload the table view; just apply the configuration
    /// directly to the cell.
    func updateTable(for speed: GameState.AnimationSpeed) {
        if let indexPath = datasource.indexPath(for: ItemWrapper.speed) {
            if let cell = tableView?.cellForRow(at: indexPath) {
                cell.contentConfiguration = SpeedCellContentConfiguration(speed: speed)
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return switch section {
        case 0: 1 // cannot say 0 without reverting to tall default height
        case 1: 46
        default: 1
        }
    }
}

/// We have two sections and correspondingly two types of cell. But a diffable data source can
/// have only one type of item identifier. Therefore our item identifier is a wrapper for each
/// of the types of cell.
enum ItemWrapper: nonisolated Hashable {
    case pref(PrefKey)
    case speed
}

/// Subclass that gives us section titles based on the section identifier. In this instance
/// we need a title only for the second section (section 1).
final class PrefsDiffableDataSource: UITableViewDiffableDataSource<String, ItemWrapper> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: snapshot().sectionIdentifiers[section]
        default: nil
        }
    }
}
