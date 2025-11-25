@testable import TTFreeCell
import Testing
import Foundation

struct StatsTests {
    let subject = Stats()
    let fileManager = MockFileManager()

    init() {
        services.fileManager = fileManager
    }

    @Test("loadStats: fetches stats from documents, sets stats property")
    func loadStats() async throws {
        let bundle = Bundle(for: MockFileManager.self)
        let url = try #require(bundle.url(forResource: "stats", withExtension: nil))
        fileManager.documentsURLtoReturn = url
        let oldStats = await(subject.stats)
        #expect(oldStats == [:])
        await subject.loadStats()
        #expect(fileManager.methodsCalled == ["urlInDocuments(name:)"])
        #expect(fileManager.name == "stats")
        let newStats = await(subject.stats)
        #expect(newStats != [:])
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
}
