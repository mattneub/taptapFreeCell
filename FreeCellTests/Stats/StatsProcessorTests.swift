@testable import TTFreeCell
import Testing
import Foundation

struct StatsProcessorTests {
    let subject = StatsProcessor()
    let presenter = MockReceiverPresenter<StatsEffect, StatsState>()
    let stats = MockStats()

    init() {
        subject.presenter = presenter
        services.stats = stats
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
}

