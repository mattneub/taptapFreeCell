import BackgroundTasks
import os.log

protocol CleanerType {
    func register()
    func cleanup(task: (any BackgroundTaskType)?)
}

final class Cleaner: CleanerType {
    var registered = false

    /// Register our task. Be sure to register it only once.
    func register() {
        guard !registered else {
            return
        }
        let registered = services.taskScheduler.register(
            forTaskWithIdentifier: "com.neuburg.matt.FreeCell.cleanup2", using: nil
        ) { task in
            self.cleanup(task: task)
        }
        self.registered = registered
    }

    /// The task is being called! Hop into async and do the actual work.
    func cleanup(task: (any BackgroundTaskType)?) {
        Task { @concurrent in
            await cleanupAsync(task: task)
        }
    }


    /// We describe success as true, but if we are expired, we set it to false.
    var success = true

    func setSuccessTrue() {
        success = true
    }

    func setExpirationHandler(onTask task: (any BackgroundTaskType)?) {
        task?.expirationHandler = {
            self.success = false
        }
    }

    nonisolated
    func cleanupAsync(task: (any BackgroundTaskType)?) async {
        var progress: Progress?
        if let task = task as? BGContinuedProcessingTask {
            progress = task.progress
            progress?.totalUnitCount = Int64(await services.fileManager.countUrlsInDocuments())
        }
        await setSuccessTrue()
        await setExpirationHandler(onTask: task)
        var count = 0
        // cycle thru all documents, deleting all except stats, yielding on every loop to give
        // expiration handler a chance to run
        do {
            let list = try await services.fileManager.urlsInDocuments()
            for url in list {
                if url.lastPathComponent == "stats" {
                    continue
                }
                try await services.fileManager.removeItem(at: url)
                count += 1
                progress?.completedUnitCount = Int64(count)
                // every time thru the loop, pause and check for expiration
                try? await Task.sleep(for: .milliseconds(0.1)) // do this even when testing!
                if !(await success) {
                    break
                }
            }
            let success = await self.success
            if success {
                await logger.log("settings task completed success")
            } else {
                await logger.log("setting task completed failure")
            }
            await task?.setTaskCompleted(success: success)
        } catch {
            await logger.log("setting task completed failure")
            await task?.setTaskCompleted(success: false)
        }
    }
}
