import Foundation

protocol StatsType: Actor {
    var stats: StatsDictionary { get }

    func loadStats() async
    func saveStat(_ stat: Stat) async throws
    func doMigration3() async throws
}

/// Actor who loads and saves the stats dictionary. This involves use of a property list
/// decoder / encoder, which is a slow business — which is why this is an actor.
actor Stats: StatsType {
    var stats: StatsDictionary = [:]

    /// Intended to be called once at app launch.
    /// Read stats from disk; also migrate and save if necessary. Takes about five seconds
    /// on my machine, which is probably longer than any other user. :)
    func loadStats() async {
        await loadStatsFile()
        #if targetEnvironment(simulator)
            // always do the migration running in simulator, but not during unit tests
            try? await unlessTesting {
                await services.persistence.setDidMigration3(false)
            }
        #endif
        let didMigration3 = await services.persistence.didMigration3()
        if !didMigration3 {
            do {
                try await doMigration3()
                await services.persistence.setDidMigration3(true)
            } catch {
                print("failed to do migration 3")
            }
        }
    }

    /// Subroutine of `loadStats`, for neatness.
    private func loadStatsFile() async {
        if let url = await services.fileManager.urlInDocuments(name: Defaults.stats) {
            do {
                let data = try Data(contentsOf: url, options: [])
                let stats = try PropertyListDecoder().decode(StatsDictionary.self, from: data)
                self.stats = stats
            } catch {
                print(error)
            }
        }
    }

    /// Intended to be called _once_ in the lifetime of the _user_! Convert the keys of `stats`
    /// dictionary to the newer style of layout description. No great harm if we ever do this
    /// a second time; it will take time but it will make no change. I describe this as
    /// migration 3 because there were two earlier migrations, now removed from the code.
    func doMigration3() async throws {
        stats = stats.mapKeys { $0.trimmingWhitespacesFromLineEnds }
        if let url = await services.fileManager.urlInDocuments(name: Defaults.stats) {
            let data = try PropertyListEncoder().encode(stats)
            try data.write(to: url)
        }
    }

    /// Intended to be called when a game ends by win or loss. Save the given Stat into the
    /// stats dictionary and save the stats dictionary to disk.
    func saveStat(_ stat: Stat) async throws {
        let key = await stat.initialLayout.tableauDescription
        stats[key] = stat
        if let url = await services.fileManager.urlInDocuments(name: Defaults.stats) {
            let data = try PropertyListEncoder().encode(stats)
            try data.write(to: url)
        }
    }
}

