@testable import TTFreeCell
import Testing
import Foundation

struct StatsTests {
    let subject = Stats()
    let fileManager = MockFileManager()
    let persistence = MockPersistence()

    init() {
        services.fileManager = fileManager
        services.persistence = persistence
    }

    @Test("loadStats: fetches stats from documents, sets stats property")
    func loadStats() async throws {
        persistence.migrationToReturn = true
        let bundle = Bundle(for: MockFileManager.self)
        let url = try #require(bundle.url(forResource: "stats", withExtension: nil))
        fileManager.documentsURLtoReturn = url
        let oldStats = await(subject.stats)
        #expect(oldStats == [:])
        await subject.loadStats()
        #expect(persistence.methodsCalled == ["didMigration3()"])
        #expect(fileManager.methodsCalled == ["urlInDocuments(name:)"])
        #expect(fileManager.name == "stats")
        let newStats = await(subject.stats)
        #expect(newStats != [:])
    }

    @Test("loadStats: if no migration yet, rewrites the stats keys, sets persistence migration as done")
    func loadStatsNotMigratedYet() async throws {
        // preparation: load the unmigrated stats so can see them
        persistence.migrationToReturn = true
        let bundle = Bundle(for: MockFileManager.self)
        let url = try #require(bundle.url(forResource: "stats", withExtension: nil))
        fileManager.documentsURLtoReturn = url
        await subject.loadStats()
        persistence.methodsCalled = []
        fileManager.methodsCalled = []
        fileManager.name = ""
        let keys = await subject.stats.keys
        let sampleKey = Array(keys)[0]
        let value = await subject.stats[sampleKey]
        let expectedMigratedKeys = Set(keys.map { $0.trimmingWhitespacesFromLineEnds })
        // all of that was just prep, this is the test!
        persistence.migrationToReturn = false
        await subject.loadStats()
        #expect(persistence.methodsCalled == ["didMigration3()", "setDidMigration3(_:)"])
        #expect(persistence.migrationSet == true)
        let migratedKeys = await subject.stats.keys
        #expect(Set(migratedKeys) == expectedMigratedKeys)
        let newValue = await subject.stats[sampleKey.trimmingWhitespacesFromLineEnds]
        #expect(newValue == value)
    }

    @Test("saveStats: saves the given stat into stats with its initial layout as key, saves to documents")
    func saveStats() async throws {
        let uuid = UUID().uuidString
        let url = URL.temporaryDirectory.appendingPathComponent(uuid)
        fileManager.documentsURLtoReturn = url
        var layout = Layout()
        layout.columns[0].cards = [Card(rank: .jack, suit: .hearts)]
        let stat = Stat(
            dateFinished: Date.distantPast,
            won: true,
            initialLayout: layout,
            movesCount: 4,
            timeTaken: 200,
            codes: ["manny", "moe", "jack"]
        )
        try await subject.saveStat(stat)
        #expect(fileManager.methodsCalled == ["urlInDocuments(name:)"])
        #expect(fileManager.name == "stats")
        let data = try Data(contentsOf: url)
        let stats = try PropertyListDecoder().decode(StatsDictionary.self, from: data)
        let result = try #require(stats[layout.tableauDescription])
        #expect(result == stat)
    }

    @Test("doMigration3: rewrites the stat keys as expected")
    func doMigration3() async throws {
        let bundle = Bundle(for: MockFileManager.self)
        let url = try #require(bundle.url(forResource: "stats", withExtension: nil))
        fileManager.documentsURLtoReturn = url
        await subject.loadStats() // unmigrated stats
        let keys = await subject.stats.keys
        let sampleKey = Array(keys)[0]
        let value = await subject.stats[sampleKey]
        let expectedMigratedKeys = Set(keys.map { $0.trimmingWhitespacesFromLineEnds })
        // this is the test
        try await subject.doMigration3()
        let migratedKeys = await subject.stats.keys
        #expect(Set(migratedKeys) == expectedMigratedKeys)
        let newValue = await subject.stats[sampleKey.trimmingWhitespacesFromLineEnds]
        #expect(newValue == value)
    }
}
