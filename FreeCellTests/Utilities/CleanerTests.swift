@testable import TTFreeCell
import Testing
import Foundation
import BackgroundTasks
import WaitWhile

private struct CleanerTests {
    let subject = Cleaner()
    let scheduler = MockTaskScheduler()
    let fileManager = MockFileManager()

    init() {
        services.taskScheduler = scheduler
        services.fileManager = fileManager
    }

    @Test("register: calls scheduler register once")
    func register() {
        subject.register()
        #expect(scheduler.methodsCalled == ["register(forTaskWithIdentifier:using:launchHandler:)"])
        #expect(scheduler.identifier == "com.neuburg.matt.FreeCell.cleanup2")
        #expect(subject.registered == true)
        subject.register()
        #expect(scheduler.methodsCalled == ["register(forTaskWithIdentifier:using:launchHandler:)"]) // not twice
    }

    @Test("register: launch handler calls cleanup")
    func launchHandler() async throws {
        // can't test this part! I can't make a BGTask so I can't call the handler
    }

    @Test("cleanup: performs cleanup")
    func cleanup() async throws {
        fileManager.countToReturn = 3
        fileManager.urlsToReturn = [URL(string: "manny")!, URL(string: "moe")!, URL(string: "stats")!]
        let task = MockBackgroundTask()
        subject.cleanup(task: task)
        await #while(task.success == nil)
        #expect(fileManager.methodsCalled == [
            "urlsInDocuments()", "removeItem(at:)", "removeItem(at:)"
        ])
        #expect(fileManager.urlsDeleted == [URL(string: "manny")!, URL(string: "moe")!])
        #expect(task.success == true)
    }

    @Test("cleanup: fails gracefully if task expiration handler is called")
    func cleanupExpires() async throws {
        fileManager.countToReturn = 3
        fileManager.urlsToReturn = [
            URL(string: "manny")!, URL(string: "moe")!,
            URL(string: "manny")!, URL(string: "moe")!,
            URL(string: "manny")!, URL(string: "moe")!,
            URL(string: "manny")!, URL(string: "moe")!,
            URL(string: "manny")!, URL(string: "moe")!,
            URL(string: "manny")!, URL(string: "moe")!,
            URL(string: "manny")!, URL(string: "moe")!,
            URL(string: "manny")!, URL(string: "moe")!,
            URL(string: "manny")!, URL(string: "moe")!,
        ]
        let task = MockBackgroundTask()
        subject.cleanup(task: task)
        await #while(task.expirationHandler == nil)
        task.expirationHandler?()
        await #while(task.success == nil)
        #expect(task.success == false)
        #expect(fileManager.urlsDeleted.count < 18) // proving that we stopped before doing all of them
    }

}
