import Foundation

protocol StatsType: Actor {
    var stats: StatsDictionary { get }

    func loadStats() async
    func saveStat(_ stat: Stat) async throws
}

/// Actor who loads and saves the stats dictionary. This involves use of a property list
/// decoder / encoder, which is a slow business — which is why this is an actor.
actor Stats: StatsType {
    var stats: StatsDictionary = [:]

    /// Intended to be called _once_ near the launch of the app. Load a copy of the stats
    /// dictionary from disk and store it in a property for the duration of the app, to be
    /// used e.g. for display of statistics.
    func loadStats() async {
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

