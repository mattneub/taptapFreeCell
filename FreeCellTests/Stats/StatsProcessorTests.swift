@testable import TTFreeCell
import Testing
import Foundation

private struct StatsProcessorTests {
    let subject = StatsProcessor()
    let presenter = MockReceiverPresenter<StatsEffect, StatsState>()
    let coordinator = MockRootCoordinator()
    fileprivate let delegate = MockDelegate()
    let stats = MockStats()

    init() {
        subject.presenter = presenter
        subject.coordinator = coordinator
        subject.delegate = delegate
        services.stats = stats
    }

    @Test("receive delete: sends delete to stats, then fetches and stores stats")
    func delete() async {
        let statsDictionary: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: Layout(), movesCount: 1, timeTaken: 1),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: true, initialLayout: Layout(), movesCount: 2, timeTaken: 2),
        ]
        stats.stats = statsDictionary
        await subject.receive(.delete(key: "ha"))
        #expect(stats.methodsCalled == ["delete(key:)"])
        #expect(stats.key == "ha")
        #expect(subject.state.stats == statsDictionary)
    }

    @Test("receive initialData: presents the stats")
    func initialData() async {
        let statsDictionary: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: Layout(), movesCount: 1, timeTaken: 1),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: true, initialLayout: Layout(), movesCount: 2, timeTaken: 2),
        ]
        stats.stats = statsDictionary
        await subject.receive(.initialData)
        #expect(presenter.statesPresented.last?.stats == statsDictionary)
    }

    @Test("receive resume: puts up an alert")
    func resume() async {
        coordinator.buttonTitleToReturn = "Cancel"
        await subject.receive(.resume(key: "ho"))
        #expect(coordinator.methodsCalled == ["showAlert(title:message:buttonTitles:)"])
        #expect(coordinator.title == "Resume Lost Game")
        #expect(coordinator.message == "Resume playing lost game?")
        #expect(coordinator.buttonTitles == ["Cancel", "Resume"])
    }

    @Test("receive resume: if user says Cancel or key is not in dictionary, nothing happens")
    func resumeCancelOrNoKey() async {
        let statsDictionary: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: Layout(), movesCount: 1, timeTaken: 1),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: true, initialLayout: Layout(), movesCount: 2, timeTaken: 2),
        ]
        subject.state.stats = statsDictionary
        coordinator.buttonTitleToReturn = "Cancel"
        await subject.receive(.resume(key: "ho"))
        #expect(delegate.methodsCalled.isEmpty)
        coordinator.buttonTitleToReturn = "Resume"
        await subject.receive(.resume(key: "teehee"))
        #expect(delegate.methodsCalled.isEmpty)
    }

    @Test("receive resume: if user says Resume and key is in dictionary, calls delegate resume")
    func resumeResume() async {
        let statsDictionary: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: Layout(), movesCount: 1, timeTaken: 1),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: true, initialLayout: Layout(), movesCount: 2, timeTaken: 2),
        ]
        subject.state.stats = statsDictionary
        coordinator.buttonTitleToReturn = "Resume"
        await subject.receive(.resume(key: "ho"))
        #expect(delegate.methodsCalled == ["resume(stat:)"])
        #expect(delegate.stat == Stat(dateFinished: Date(timeIntervalSince1970: 3), won: true, initialLayout: Layout(), movesCount: 2, timeTaken: 2))
    }

    @Test("receive totalChanged sends totalChanged")
    func totalChanged() async {
        await subject.receive(.totalChanged(total: 3, won: 2))
        #expect(presenter.thingsReceived == [.totalChanged(total: 3, won: 2)])
    }
}

fileprivate final class MockDelegate: StatsDelegate {
    var methodsCalled = [String]()
    var stat: Stat?
    func resume(stat: Stat) async {
        methodsCalled.append(#function)
        self.stat = stat
    }
}

