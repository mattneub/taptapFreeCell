import Foundation
import BackgroundTasks

protocol StatsType: Actor {
    var stats: StatsDictionary { get }

    func loadStats() async
    func saveStat(_ stat: Stat) async throws
    func doMigration3() async throws
    func cleanup(task: (any BackgroundTaskType)?) async
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
        // if there are a lot of things in documents, submit a background processing task to delete them
        let listCount = await services.fileManager.countUrlsInDocuments()
        if listCount > 100 {
            let request = BGProcessingTaskRequest(identifier: "com.neuburg.matt.freecell.cleanup")
            request.requiresNetworkConnectivity = false
            request.requiresExternalPower = false
            request.earliestBeginDate = Date.now + 120
            do {
                try await services.taskScheduler.submit(request)
            } catch {
                print(error)
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

    /// Called from app delegate if we are told to perform the background task submitted
    /// in `loadStats`.
    func cleanup(task: (any BackgroundTaskType)?) async {
        // describe success as true unless the task's expiration handler is called
        var success = true
        task?.expirationHandler = {
            success = false
        }
        // cycle thru all documents, deleting all except stats, yielding on every loop to give
        // expiration handler a chance to run
        do {
            let list = try await services.fileManager.urlsInDocuments()
            for url in list {
                if url.lastPathComponent == "stats" {
                    continue
                }
                try await services.fileManager.removeItem(at: url)
                // every time thru the loop, yield and check for expiration
                await Task.yield()
                if !success {
                    break
                }
            }
            task?.setTaskCompleted(success: success)
        } catch {
            task?.setTaskCompleted(success: false)
        }
    }
}

