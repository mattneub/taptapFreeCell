import Foundation
@testable import TTFreeCell

actor MockStats: StatsType {
    nonisolated(unsafe) var methodsCalled = [String]()
    var stats: StatsDictionary = [:]
    nonisolated(unsafe) var stat: Stat?

    func loadStats() async {
        methodsCalled.append(#function)
    }

    func saveStat(_ stat: Stat) async throws {
        methodsCalled.append(#function)
        self.stat = stat
    }
}
