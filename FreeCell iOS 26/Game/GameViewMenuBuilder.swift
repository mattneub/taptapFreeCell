import UIKit
import BackgroundTasks

protocol GameViewMenuBuilderType {
    func buildMenu(processor: (any Receiver<GameAction>)?) -> UIMenu
}

/// Helper object that builds the popdown menu for the second bar button item.
struct GameViewMenuBuilder: GameViewMenuBuilderType {

    /// The deferred menu item builder, so we can inject a mock for testing.
    var deferredMenuItemBuilder: DeferredMenuItemBuilder = DeferredMenuItemBuilder()

    func buildMenu(processor: (any Receiver<GameAction>)?) -> UIMenu {
        let rulesAction = UIAction(
            title: "Rules",
            image: UIImage(systemName: "lightbulb")
        ) { _ in }
        let tapTapAction = UIAction(
            title: "About",
            image: UIImage(systemName: "questionmark.circle")
        ) { _ in }
        let statsAction = MyUIAction(
            myTitle: "Statistics",
            image: UIImage(systemName: "pencil.and.list.clipboard")
        ) { [weak processor] _ in
            Task {
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.4)) // give the menu time to collapse
                }
                await processor?.receive(.showStats)
            }
        }
        let cleanupAction = deferredMenuItemBuilder.build(buildCleanupActionProvider)
        let prefsAction = UIAction(
            title: "Settings",
            image: UIImage(systemName: "gear")
        ) { _ in }
        let importExportAction = UIAction(
            title: "Import / Export",
            image: UIImage(systemName: "arrow.up.arrow.down.circle")
        ) { _ in }
        return UIMenu(title: "", children: [
            rulesAction,
            tapTapAction,
            statsAction,
            cleanupAction,
            importExportAction,
            prefsAction
        ])
    }

    func buildCleanupActionProvider(_ handler: ([UIAction]) -> Void) {
        let action = MyUIAction(
            myTitle: "Cleanup",
            image: UIImage(systemName: "tray.full")
        ) { _ in
            Task {
                try? await unlessTesting {
                    try? await Task.sleep(for: .seconds(0.4)) // give the menu time to collapse
                }
                // register our task and submit it, all in one breath
                services.cleaner.register()
                let task = BGContinuedProcessingTaskRequest(
                    identifier: "com.neuburg.matt.FreeCell.cleanup2",
                    title: "Cleanup",
                    subtitle: "Cleaning disk storage..."
                )
                do {
                    try services.taskScheduler.submit(task)
                } catch {
                    print(error)
                }
            }
        }
        let count = services.fileManager.countUrlsInDocuments()
        action.attributes = .hidden
        if count > 100 {
            action.attributes = []
        }
        handler([action])
    }
}

