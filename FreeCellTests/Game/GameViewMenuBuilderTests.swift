@testable import TTFreeCell
import Testing
import UIKit
import WaitWhile
import BackgroundTasks

private struct GameViewMenuBuilderTests {
    @Test("menu is correctly built")
    func build() async throws {
        let fileManager = MockFileManager()
        fileManager.countToReturn = 1
        services.fileManager = fileManager
        let processor = MockReceiver<GameAction>()
        var subject = GameViewMenuBuilder()
        let mockBuilder = MockDeferredMenuItemBuilder()
        subject.deferredMenuItemBuilder = mockBuilder
        let result = subject.buildMenu(processor: processor)
        #expect(result.title == "")
        #expect(result.children.count == 6)
        do {
            let action = try #require(result.children[0] as? UIAction)
            #expect(action.title == "Rules")
            #expect(action.image == UIImage(systemName: "lightbulb"))
            (action as? MyUIAction)?.handler?(action)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived == [.showRules])
        }
        processor.thingsReceived = []
        do {
            let action = try #require(result.children[1] as? UIAction)
            #expect(action.title == "About")
            #expect(action.image == UIImage(systemName: "questionmark.circle"))
            (action as? MyUIAction)?.handler?(action)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived == [.showHelp])
        }
        processor.thingsReceived = []
        do {
            let action = try #require(result.children[2] as? UIAction)
            #expect(action.title == "Statistics")
            #expect(action.image == UIImage(systemName: "pencil.and.list.clipboard"))
            (action as? MyUIAction)?.handler?(action)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived == [.showStats])
        }
        processor.thingsReceived = []
        do {
            #expect(mockBuilder.handler != nil)
            #expect(mockBuilder.methodsCalled == ["build(_:)"])
            let actions = mockBuilder.extractActions()
            let action = try #require(actions.first as? MyUIAction)
            #expect(action.title == "Cleanup")
            #expect(action.image == UIImage(systemName: "tray.full"))
            #expect(action.attributes == .hidden) // because there was only 1 file in documents
        }
        processor.thingsReceived = []
        do {
            let action = try #require(result.children[4] as? UIAction)
            #expect(action.title == "Import / Export")
            #expect(action.image == UIImage(systemName: "arrow.up.arrow.down.circle"))
            (action as? MyUIAction)?.handler?(action)
            await #while(processor.thingsReceived.isEmpty)
            #expect(processor.thingsReceived == [.showImportExport])
        }
        processor.thingsReceived = []
        do {
            let action = try #require(result.children[5] as? UIAction)
            #expect(action.title == "Settings")
            #expect(action.image == UIImage(systemName: "gear"))
        }
    }

    @Test("The cleanup item action behaves as expected")
    func cleanup() async throws {
        let cleaner = MockCleaner()
        services.cleaner = cleaner
        let taskScheduler = MockTaskScheduler()
        services.taskScheduler = taskScheduler
        let fileManager = MockFileManager()
        fileManager.countToReturn = 201
        services.fileManager = fileManager
        let processor = MockReceiver<GameAction>()
        var subject = GameViewMenuBuilder()
        let mockBuilder = MockDeferredMenuItemBuilder()
        subject.deferredMenuItemBuilder = mockBuilder
        let _ = subject.buildMenu(processor: processor)
        let actions = mockBuilder.extractActions()
        let action = try #require(actions.first as? MyUIAction)
        #expect(action.title == "Cleanup")
        #expect(action.image == UIImage(systemName: "tray.full"))
        #expect(action.attributes == []) // not hidden, because there were 201 files in documents
        // okay, here comes the _real_ test! what happens when the user _chooses_ this menu item?
        action.handler?(action)
        await #while(taskScheduler.methodsCalled.isEmpty)
        #expect(cleaner.methodsCalled == ["register()"])
        #expect(taskScheduler.methodsCalled == ["submit(_:)"])
        let request = try #require(taskScheduler.request as? BGContinuedProcessingTaskRequest)
        #expect(request.identifier == "com.neuburg.matt.FreeCell.cleanup2")
        #expect(request.title == "Cleanup")
        #expect(request.subtitle == "Cleaning disk storage...")
    }
}

