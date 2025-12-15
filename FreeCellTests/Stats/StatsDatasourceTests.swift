@testable import TTFreeCell
import Testing
import UIKit
import WaitWhile

private struct StatsDatasourceTests {
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

    @Test("present: configures the contents of the datasource, sends totalChanged")
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
        #expect(processor.thingsReceived == [.totalChanged(total: 2, won: 2)])
    }

    @Test("receive segmentSelected: sorts the snapshot items, sends totalChanged")
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
        await subject.receive(.sort(.date)) // reverse
        snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["hey", "ho", "ha"])
        #expect(subject.sortedData.map { $0.key } == ["hey", "ho", "ha"])
        await subject.receive(.sort(.time)) // time taken
        snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["ha", "ho", "hey"])
        #expect(subject.sortedData.map { $0.key } == ["ha", "ho", "hey"])
        await subject.receive(.sort(.moves)) // moves count
        snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["hey", "ha", "ho"])
        #expect(subject.sortedData.map { $0.key } == ["hey", "ha", "ho"])
        await subject.receive(.sort(.moves)) // reverse
        snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["ho", "ha", "hey"])
        #expect(subject.sortedData.map { $0.key } == ["ho", "ha", "hey"])
        await subject.receive(.sort(.won)) // won/lost
        snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["ha", "ho", "hey"])
        #expect(subject.sortedData.map { $0.key } == ["ha", "ho", "hey"])
        await subject.receive(.sort(.won)) // reverse
        snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["hey", "ho", "ha"])
        #expect(subject.sortedData.map { $0.key } == ["hey", "ho", "ha"])
        #expect(processor.thingsReceived.allSatisfy { $0 == .totalChanged(total: 3, won: 2) })
        #expect(processor.thingsReceived.count == 7)
    }

    @Test("receive .toggleMicrosoft filters and sorts on microsoft deal number, or unfilters and sorts on date")
    func microsoft() async {
        var layout1 = Layout()
        layout1.microsoftDealNumber = 10
        var layout2 = Layout()
        layout2.microsoftDealNumber = 20
        let stats: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: layout1, movesCount: 1, timeTaken: 3),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: true, initialLayout: layout2, movesCount: 3, timeTaken: 2),
            "ha": Stat(dateFinished: Date(timeIntervalSince1970: 4), won: false, initialLayout: Layout(), movesCount: 2, timeTaken: 1)
        ]
        await subject.present(StatsState(stats: stats))
        await subject.receive(.toggleMicrosofts)
        var snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["hey", "ho"])
        await subject.receive(.toggleMicrosofts)
        snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["ha", "ho", "hey"])
    }

    @Test("receive .segmentSelected when toggled for microsoft sorts as expect for that segment")
    func microsoftAndThenSegment() async {
        var layout1 = Layout()
        layout1.microsoftDealNumber = 10
        var layout2 = Layout()
        layout2.microsoftDealNumber = 20
        let stats: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: layout1, movesCount: 1, timeTaken: 3),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: true, initialLayout: layout2, movesCount: 3, timeTaken: 2),
            "ha": Stat(dateFinished: Date(timeIntervalSince1970: 4), won: false, initialLayout: Layout(), movesCount: 2, timeTaken: 1)
        ]
        await subject.present(StatsState(stats: stats))
        await subject.receive(.toggleMicrosofts)
        await subject.receive(.sort(.moves)) // moves count
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == ["hey", "ha", "ho"])
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

    @Test("should highlight: depends on whether the stat is won")
    func shouldHighlight() async {
        let stats: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: Layout(), movesCount: 1, timeTaken: 1),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: false, initialLayout: Layout(), movesCount: 2, timeTaken: 2),
        ]
        await subject.present(StatsState(stats: stats))
        var result = subject.tableView(tableView, shouldHighlightRowAt: IndexPath(row: 0, section: 0))
        #expect(result == true)
        result = subject.tableView(tableView, shouldHighlightRowAt: IndexPath(row: 1, section: 0))
        #expect(result == false)
    }

    @Test("didSelectRow: sends resume to the processor, deselects")
    func didSelect() async {
        let stats: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: Layout(), movesCount: 1, timeTaken: 1),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: false, initialLayout: Layout(), movesCount: 2, timeTaken: 2),
        ]
        await subject.present(StatsState(stats: stats))
        processor.thingsReceived = []
        tableView.selectRow(at: IndexPath(row: 1, section: 0), animated: false, scrollPosition: .none)
        #expect(tableView.indexPathForSelectedRow != nil)
        // all of that was prep, this is the test
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.resume(key: "ho")])
        #expect(tableView.indexPathForSelectedRow == nil)
    }

    @Test("trailing swipe actions is nil if unfiltered data is not nil")
    func trailingSwipeNil() async {
        let stats: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: Layout(), movesCount: 1, timeTaken: 1),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: false, initialLayout: Layout(), movesCount: 2, timeTaken: 2),
        ]
        await subject.present(StatsState(stats: stats))
        await subject.receive(.toggleMicrosofts)
        var result = subject.tableView(tableView, trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: 0))
        #expect(result == nil)
        await subject.receive(.toggleMicrosofts)
        result = subject.tableView(tableView, trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: 0))
        #expect(result != nil)
        #expect(result?.performsFirstActionWithFullSwipe == false)
        #expect(result?.actions.count == 3)
        #expect(result?.actions[0].title == "Delete")
        #expect(result?.actions[1].title == "Export")
        #expect(result?.actions[2].title == "View")
        #expect(result?.actions[0].style == .destructive)
        #expect(result?.actions[1].backgroundColor == .systemGreen)
        #expect(result?.actions[2].backgroundColor == .systemBlue)
    }

    @Test("trailing swipe action 0 removes row from sorted data, updates table, sends delete with key")
    func trailingSwipeDelete() async throws {
        makeWindow(view: tableView)
        let stats: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: Layout(), movesCount: 1, timeTaken: 1),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: false, initialLayout: Layout(), movesCount: 2, timeTaken: 2),
        ]
        await subject.present(StatsState(stats: stats))
        #expect(subject.sortedData.count == 2)
        #expect(processor.thingsReceived.first == .totalChanged(total: 2, won: 1))
        let config = subject.tableView(tableView, trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: 0))
        let action = try #require(config?.actions.first as? MyUIContextualAction)
        var ok: Bool?
        func completion(_ success: Bool) { ok = success }
        action.myHandler?(action, UIView(), completion)
        #expect(subject.sortedData.count == 1)
        #expect(subject.sortedData.first?.key == "hey") // "ho" was deleted
        await #while(processor.thingsReceived.count < 3)
        #expect(processor.thingsReceived[1] == .totalChanged(total: 1, won: 1))
        #expect(processor.thingsReceived[2] == .delete(key: "ho"))
        #expect(ok == true)
    }

    @Test("trailing swipe action 1 sends processor mail")
    func trailingSwipeExport() async throws {
        let stats: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: Layout(), movesCount: 1, timeTaken: 1),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: false, initialLayout: Layout(), movesCount: 2, timeTaken: 2),
        ]
        await subject.present(StatsState(stats: stats))
        let config = subject.tableView(tableView, trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: 0))
        let action = try #require(config?.actions[1] as? MyUIContextualAction)
        var ok: Bool?
        func completion(_ success: Bool) { ok = success }
        action.myHandler?(action, UIView(), completion)
        await #while(processor.thingsReceived.count < 2)
        let expected = Stat(dateFinished: Date(timeIntervalSince1970: 3), won: false, initialLayout: Layout(), movesCount: 2, timeTaken: 2)
        #expect(processor.thingsReceived.last == .mail(stat: expected))
        #expect(ok == true)
    }

    @Test("trailing swipe action 2 sends processor snapshot")
    func trailingSwipeSnapshot() async throws {
        let stats: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: Layout(), movesCount: 1, timeTaken: 1),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: false, initialLayout: Layout(), movesCount: 2, timeTaken: 2),
        ]
        await subject.present(StatsState(stats: stats))
        let config = subject.tableView(tableView, trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: 0))
        let action = try #require(config?.actions[2] as? MyUIContextualAction)
        var ok: Bool?
        func completion(_ success: Bool) { ok = success }
        action.myHandler?(action, UIView(), completion)
        await #while(processor.thingsReceived.count < 2)
        let expected = Stat(dateFinished: Date(timeIntervalSince1970: 3), won: false, initialLayout: Layout(), movesCount: 2, timeTaken: 2)
        #expect(processor.thingsReceived.last == .snapshot(stat: expected))
        #expect(ok == true)
    }
}
