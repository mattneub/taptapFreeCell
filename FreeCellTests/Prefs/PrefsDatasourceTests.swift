@testable import TTFreeCell
import Testing
import UIKit
import WaitWhile

private struct PrefsDatasourceTests {
    let subject: PrefsDatasource!
    let processor = MockReceiver<PrefsAction>()
    let tableView = UITableView()

    init() {
        subject = PrefsDatasource(tableView: tableView, processor: processor)
    }

    @Test("Initialization: creates and configures the data source, configures the table view")
    func initialize() throws {
        let datasource = try #require(subject.datasource)
        #expect(tableView.dataSource === datasource)
        #expect(tableView.delegate === subject)
        #expect(tableView.rowHeight == 52)
        #expect(tableView.allowsSelection == false)
        #expect(tableView.sectionHeaderHeight == 0)
    }

    @Test("present: sets data, configures the contents of the datasource")
    func present() async {
        let prefs: [Pref] = [
            Pref(key: .automoveToFoundations, value: true),
            Pref(key: .automoveOnFirstTap, value: false)
        ]
        await subject.present(PrefsState(prefs: prefs, speed: .glacial))
        #expect(subject.data == [
            .automoveToFoundations: Pref(key: .automoveToFoundations, value: true),
            .automoveOnFirstTap: Pref(key: .automoveOnFirstTap, value: false)
        ])
        #expect(subject.speed == .glacial)
        let snapshot = subject.datasource.snapshot()
        #expect(snapshot.sectionIdentifiers == ["dummy", "Card Animation Speed"])
        #expect(snapshot.itemIdentifiers(inSection: "dummy") == [
            ItemWrapper.pref(.automoveToFoundations),
            ItemWrapper.pref(.automoveOnFirstTap)
        ])
        #expect(snapshot.itemIdentifiers(inSection: "Card Animation Speed") == [
            ItemWrapper.speed
        ])
    }

    @Test("present: configures cells correctly")
    func presentCells() async throws {
        makeWindow(view: tableView)
        let prefs: [Pref] = [
            Pref(key: .automoveToFoundations, value: true),
            Pref(key: .automoveOnFirstTap, value: false)
        ]
        await subject.present(PrefsState(prefs: prefs, speed: .glacial))
        let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0))
        let config1 = try #require(cell1?.contentConfiguration as? PrefCellContentConfiguration)
        #expect(config1.text == "Automove To Foundations") // that's enough, see pref content view tests
        let cell2 = tableView.cellForRow(at: IndexPath(row: 0, section: 1))
        let config2 = try #require(cell2?.contentConfiguration as? SpeedCellContentConfiguration)
        #expect(config2.speed == .glacial)
    }

    @Test("receive prefChanged: updates data, updates cell config")
    func prefChanged() async throws {
        makeWindow(view: tableView)
        let prefs: [Pref] = [
            Pref(key: .automoveToFoundations, value: true),
            Pref(key: .automoveOnFirstTap, value: false)
        ]
        await subject.present(PrefsState(prefs: prefs, speed: .glacial))
        #expect(subject.data[.automoveToFoundations]?.value == true)
        let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0))
        var config1 = try #require(cell1?.contentConfiguration as? PrefCellContentConfiguration)
        #expect(config1.value == true)
        // that was prep, this is the test
        await subject.receive(.prefChanged(.automoveToFoundations, value: false))
        #expect(subject.data[.automoveToFoundations]?.value == false)
        config1 = try #require(cell1?.contentConfiguration as? PrefCellContentConfiguration)
        #expect(config1.value == false)
    }

    @Test("receive speedChanged: updates speed, updates cell config")
    func speedChanged() async throws {
        makeWindow(view: tableView)
        let prefs: [Pref] = [
            Pref(key: .automoveToFoundations, value: true),
            Pref(key: .automoveOnFirstTap, value: false)
        ]
        await subject.present(PrefsState(prefs: prefs, speed: .glacial))
        #expect(subject.speed == .glacial)
        let cell2 = tableView.cellForRow(at: IndexPath(row: 0, section: 1))
        var config2 = try #require(cell2?.contentConfiguration as? SpeedCellContentConfiguration)
        #expect(config2.speed == .glacial)
        // that was prep, this is the test
        await subject.receive(.speedChanged(index: 0)) // fast
        #expect(subject.speed == .fast)
        config2 = try #require(cell2?.contentConfiguration as? SpeedCellContentConfiguration)
        #expect(config2.speed == .fast)
    }

    @Test("section header heights are 1 and 46")
    func sectionHeaderHeights() {
        #expect(subject.tableView(tableView, heightForHeaderInSection: 0) == 1)
        #expect(subject.tableView(tableView, heightForHeaderInSection: 1) == 46)
    }

    @Test("titleForHeaderInSection: is nil and section identifier")
    func titleForHeader() async {
        let prefs: [Pref] = [
            Pref(key: .automoveToFoundations, value: true),
            Pref(key: .automoveOnFirstTap, value: false)
        ]
        await subject.present(PrefsState(prefs: prefs, speed: .glacial))
        #expect(subject.datasource.tableView(tableView, titleForHeaderInSection: 0) == nil)
        #expect(subject.datasource.tableView(tableView, titleForHeaderInSection: 1) == "Card Animation Speed")
    }
}
