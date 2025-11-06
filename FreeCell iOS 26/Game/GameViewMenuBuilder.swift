import UIKit

protocol GameViewMenuBuilderType {
    func buildMenu() -> UIMenu
}

/// Helper object that builds the popdown menu for the second bar button item.
struct GameViewMenuBuilder: GameViewMenuBuilderType {
    func buildMenu() -> UIMenu {
        let rulesAction = UIAction(
            title: "Rules",
            image: UIImage(systemName: "lightbulb")
        ) { _ in }
        let tapTapAction = UIAction(
            title: "About",
            image: UIImage(systemName: "questionmark.circle")
        ) { _ in }
        let statsAction = UIAction(
            title: "Statistics",
            image: UIImage(systemName: "pencil.and.list.clipboard")
        ) { _ in }
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
