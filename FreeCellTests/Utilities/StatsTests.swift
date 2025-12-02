@testable import TTFreeCell
import Testing
import Foundation
import BackgroundTasks

private struct StatsTests {
    let subject = Stats()
    let fileManager = MockFileManager()
    let persistence = MockPersistence()
    let scheduler = MockTaskScheduler()

    init() {
        services.fileManager = fileManager
        services.persistence = persistence
        services.taskScheduler = scheduler
    }

    @Test("setStats: back door works")
    func setStats() async {
        #expect(await subject.stats.isEmpty)
        let stat = Stat(
            dateFinished: Date.distantPast,
            won: true,
            initialLayout: Layout(),
            movesCount: 4,
            timeTaken: 200,
            codes: ["manny", "moe", "jack"]
        )
        await subject.setStats(["ho": stat])
        #expect(await subject.stats == ["ho": stat])
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
        #expect(fileManager.methodsCalled == ["urlInDocuments(name:)", "countUrlsInDocuments()"])
        #expect(fileManager.name == "stats")
        let newStats = await(subject.stats)
        #expect(newStats != [:])
        #expect(scheduler.methodsCalled.isEmpty)
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
        #expect(scheduler.methodsCalled.isEmpty)
    }

    @Test("loadStats: if documents count is big, schedules cleanup background task")
    func loadStatsCleanup() async throws {
        fileManager.countToReturn = 200
        persistence.migrationToReturn = true
        let bundle = Bundle(for: MockFileManager.self)
        let url = try #require(bundle.url(forResource: "stats", withExtension: nil))
        fileManager.documentsURLtoReturn = url
        await subject.loadStats()
        #expect(scheduler.methodsCalled == ["submit(_:)"])
        #expect(scheduler.request?.identifier == "com.neuburg.matt.freecell.cleanup")
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

    @Test("cleanup: gets list of documents contents, deletes all except stats, calls task completed")
    func cleanup() async {
        let task = MockBackgroundTask()
        fileManager.urlsToReturn = [
            URL(string: "file://whatever/manny")!,
            URL(string: "file://whatever/moe")!,
            URL(string: "file://whatever/jack")!,
            URL(string: "file://whatever/stats")!,
        ]
        await subject.cleanup(task: task)
        #expect(fileManager.urlsDeleted == [
            URL(string: "file://whatever/manny")!,
            URL(string: "file://whatever/moe")!,
            URL(string: "file://whatever/jack")!,
        ])
        #expect(task.expirationHandler != nil)
        #expect(task.methodsCalled == ["setTaskCompleted(success:)"])
        #expect(task.success == true)
    }

    @Test("delete: deletes that key, saves the stats")
    func delete() async throws {
        let uuid = UUID().uuidString
        let url = URL.temporaryDirectory.appendingPathComponent(uuid)
        fileManager.documentsURLtoReturn = url
        let stat = Stat(
            dateFinished: Date.distantPast,
            won: true,
            initialLayout: Layout(),
            movesCount: 4,
            timeTaken: 200,
            codes: ["manny", "moe", "jack"]
        )
        await subject.setStats(["ho": stat, "hey": stat])
        try await subject.delete(key: "ho")
        #expect(await subject.stats == ["hey": stat])
        #expect(fileManager.methodsCalled == ["urlInDocuments(name:)"])
        #expect(fileManager.name == "stats")
        let data = try Data(contentsOf: url)
        let stats = try PropertyListDecoder().decode(StatsDictionary.self, from: data)
        #expect(stats == ["hey": stat])
    }
}
