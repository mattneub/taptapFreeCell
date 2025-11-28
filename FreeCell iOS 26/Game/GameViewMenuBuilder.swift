import UIKit

protocol GameViewMenuBuilderType {
    func buildMenu(processor: (any Receiver<GameAction>)?) -> UIMenu
}

/// Helper object that builds the popdown menu for the second bar button item.
struct GameViewMenuBuilder: GameViewMenuBuilderType {
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
            importExportAction,
            prefsAction
        ])
    }
}
