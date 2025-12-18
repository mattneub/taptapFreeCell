import UIKit
import os.log

/// The single Services instance is rooted here.
@MainActor
var services = Services()

let logger = Logger(subsystem: "freecell", category: "debugging")

/// Maximum width for our layout, no matter how wide the window/view may be.
let MAXWIDTH: CGFloat = 700

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return true
    }

    /// We apply one level of indirection so that (1) we don't build the menu when testing, and
    /// (2) we can inject a mock for testing the menu itself.
    override func buildMenu(with builder: any UIMenuBuilder) {
        unlessTesting {
            buildMenu(with: MenuBuilderWrapper(builder: builder))
        }
    }

    /// Wrapper for our calls to the menu builder, so we can inject a mock when testing.
    func buildMenu(with builder: MenuBuilderWrapper) {
        let dealItem = UIKeyCommand(
            title: "New Deal",
            image: UIImage(systemName: "square.3.layers.3d.down.forward"),
            action: #selector(GameViewController.doDeal),
            input: "N",
            modifierFlags: .command,
            alternates: [
                UICommandAlternate(
                    title: "New Numbered Deal",
                    action: #selector(GameViewController.doMenuMicrosoftDeal),
                    modifierFlags: .shift
                )
            ]
        )
        let undoItem = UIKeyCommand(
            title: "Undo Move",
            image: UIImage(systemName: "arrow.uturn.backward"),
            action: #selector(GameViewController.doUndo),
            input: UIKeyCommand.inputLeftArrow,
            modifierFlags: .command,
            alternates: [
                UICommandAlternate(
                    title: "Undo All Moves",
                    action: #selector(GameViewController.doUndoAll),
                    modifierFlags: .shift
                )
            ]
        )
        let redoItem = UIKeyCommand(
            title: "Redo Move",
            image: UIImage(systemName: "arrow.uturn.forward"),
            action: #selector(GameViewController.doRedo),
            input: UIKeyCommand.inputRightArrow,
            modifierFlags: .command,
            alternates: [
                UICommandAlternate(
                    title: "Redo All Moves",
                    action: #selector(GameViewController.doRedoAll),
                    modifierFlags: .shift
                )
            ]
        )
        let importItem = UICommand(
            title: "Import / Export",
            image: UIImage(systemName: "arrow.up.arrow.down.circle"),
            action: #selector(GameViewController.doImportExport)
        )
        builder.insertElements([dealItem, undoItem, redoItem, importItem], atStartOfMenu: .file)
        let statisticsItem = UICommand(
            title: "Statistics",
            image: UIImage(systemName: "pencil.and.list.clipboard"),
            action: #selector(GameViewController.doStatistics)
        )
        builder.insertElements([statisticsItem], atStartOfMenu: .view)
        let helpItem = UICommand(
            title: "Rules of FreeCell",
            image: UIImage(systemName: "lightbulb"),
            action: #selector(GameViewController.doRules),
        )
        let aboutItem = UICommand(
            title: "About TapTapFreeCell",
            image: UIImage(systemName: "questionmark.circle"),
            action: #selector(GameViewController.doHelp)
        )
        builder.insertElements([helpItem, aboutItem], atStartOfMenu: .help)
    }
}
