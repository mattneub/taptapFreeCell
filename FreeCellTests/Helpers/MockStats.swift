import Foundation
import BackgroundTasks
@testable import TTFreeCell

actor MockStats: StatsType {
    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var stats: StatsDictionary = [:]
    nonisolated(unsafe) var stat: Stat?

    func loadStats() async {
        methodsCalled.append(#function)
    }

    func doMigration3() {
        methodsCalled.append(#function)
    }

    func saveStat(_ stat: Stat) async throws {
        methodsCalled.append(#function)
        self.stat = stat
    }

    func cleanup(task: (any BackgroundTaskType)?) async {
        methodsCalled.append(#function)
    }
}
