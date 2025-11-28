@testable import TTFreeCell
import Testing
import UIKit

struct StatsDatasourceTests {
    let subject: StatsDatasource!
    let processor = MockReceiver<StatsAction>()
    let tableView = UITableView()

    init() {
        subject = StatsDatasource(tableView: tableView, processor: processor)
    }

    @Test("Initialization: creates and configures the data source, configures the table view")
    func initialize() throws {
        let datasource = try #require(subject.datasource)
        #expect(tableView.dataSource === datasource)
        #expect(tableView.delegate === subject)
        #expect(tableView.estimatedRowHeight == 50)
    }

    @Test("present: configures the contents of the datasource")
    func present() async {
        let stats: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: Layout(), movesCount: 1, timeTaken: 1),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: true, initialLayout: Layout(), movesCount: 2, timeTaken: 2),
        ]
        await subject.present(StatsState(stats: stats))
        #expect(subject.data == stats)
        #expect(subject.sortedData.map { $0.key } == ["ho", "hey"])
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.sectionIdentifiers == ["dummy"])
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["ho", "hey"]) // date order, newest first
        #expect(subject.sortedData.map { $0.key } == ["ho", "hey"])
    }

    @Test("receive segmentSelected: sorts the snapshot items")
    func segmentSelected() async {
        let stats: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: Layout(), movesCount: 1, timeTaken: 3),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: true, initialLayout: Layout(), movesCount: 3, timeTaken: 2),
            "ha": Stat(dateFinished: Date(timeIntervalSince1970: 4), won: false, initialLayout: Layout(), movesCount: 2, timeTaken: 1)
        ]
        await subject.present(StatsState(stats: stats))
        var snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["ha", "ho", "hey"])
        #expect(subject.sortedData.map { $0.key } == ["ha", "ho", "hey"])
        await subject.receive(.segmentSelected(0)) // reverse
        snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["hey", "ho", "ha"])
        #expect(subject.sortedData.map { $0.key } == ["hey", "ho", "ha"])
        await subject.receive(.segmentSelected(1)) // time taken
        snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["ha", "ho", "hey"])
        #expect(subject.sortedData.map { $0.key } == ["ha", "ho", "hey"])
        await subject.receive(.segmentSelected(2)) // moves count
        snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["hey", "ha", "ho"])
        #expect(subject.sortedData.map { $0.key } == ["hey", "ha", "ho"])
        await subject.receive(.segmentSelected(2)) // reverse
        snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["ho", "ha", "hey"])
        #expect(subject.sortedData.map { $0.key } == ["ho", "ha", "hey"])
        await subject.receive(.segmentSelected(3)) // won/lost
        snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["ha", "ho", "hey"])
        #expect(subject.sortedData.map { $0.key } == ["ha", "ho", "hey"])
        await subject.receive(.segmentSelected(3)) // reverse
        snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["hey", "ho", "ha"])
        #expect(subject.sortedData.map { $0.key } == ["hey", "ho", "ha"])
    }

    @Test("cells are correctly constructed")
    func cells() async throws {
        makeWindow(view: tableView)
        let stats: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: Layout(), movesCount: 1, timeTaken: 1),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: true, initialLayout: Layout(), movesCount: 2, timeTaken: 2),
        ]
        await subject.present(StatsState(stats: stats))
        let cell = try #require(tableView.cellForRow(at: IndexPath(row: 0, section: 0)))
        let content = try #require(cell.contentConfiguration as? StatCellContentConfiguration)
        #expect(content.date == Date(timeIntervalSince1970: 3))
        #expect(content.won == true)
        #expect(content.movesCount == 2)
        #expect(content.time == 2)
    }
}
