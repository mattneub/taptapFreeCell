@testable import TTFreeCell
import Testing
import UIKit

@MainActor
private struct AppDelegateTests {
    @Test("menu is correctly built")
    func menu() throws {
        let subject = AppDelegate()
        let builder = MockMenuBuilderWrapper(builder: nil)
        subject.buildMenu(with: builder)
        #expect(builder.thingsInserted.count == 3)
        let fileMenu = try #require(builder.thingsInserted[.file])
        #expect(fileMenu.count == 4)
        do {
            let item = try #require(fileMenu[0] as? UIKeyCommand)
            #expect(item.title == "New Deal")
            #expect(item.image == UIImage(systemName: "square.3.layers.3d.down.forward"))
            #expect(item.action == #selector(GameViewController.doDeal))
            #expect(item.input == "N")
            #expect(item.modifierFlags == .command)
            let alternate = try #require(item.alternates.first)
            #expect(alternate.title == "New Numbered Deal")
            #expect(alternate.action == #selector(GameViewController.doMenuMicrosoftDeal))
            #expect(alternate.modifierFlags == .shift)
        }
        do {
            let item = try #require(fileMenu[1] as? UIKeyCommand)
            #expect(item.title == "Undo Move")
            #expect(item.image == UIImage(systemName: "arrow.uturn.backward"))
            #expect(item.action == #selector(GameViewController.doUndo))
            #expect(item.input == UIKeyCommand.inputLeftArrow)
            #expect(item.modifierFlags == .command)
            let alternate = try #require(item.alternates.first)
            #expect(alternate.title == "Undo All Moves")
            #expect(alternate.action == #selector(GameViewController.doUndoAll))
            #expect(alternate.modifierFlags == .shift)
        }
        do {
            let item = try #require(fileMenu[2] as? UIKeyCommand)
            #expect(item.title == "Redo Move")
            #expect(item.image == UIImage(systemName: "arrow.uturn.forward"))
            #expect(item.action == #selector(GameViewController.doRedo))
            #expect(item.input == UIKeyCommand.inputRightArrow)
            #expect(item.modifierFlags == .command)
            let alternate = try #require(item.alternates.first)
            #expect(alternate.title == "Redo All Moves")
            #expect(alternate.action == #selector(GameViewController.doRedoAll))
            #expect(alternate.modifierFlags == .shift)
        }
        do {
            let item = try #require(fileMenu[3] as? UICommand)
            #expect(item.title == "Import / Export")
            #expect(item.image == UIImage(systemName: "arrow.up.arrow.down.circle"))
            #expect(item.action == #selector(GameViewController.doImportExport))
        }
        let viewMenu = try #require(builder.thingsInserted[.view])
        #expect(viewMenu.count == 1)
        do {
            let item = try #require(viewMenu[0] as? UICommand)
            #expect(item.title == "Statistics")
            #expect(item.image == UIImage(systemName: "pencil.and.list.clipboard"))
            #expect(item.action == #selector(GameViewController.doStatistics))
        }
        let helpMenu = try #require(builder.thingsInserted[.help])
        #expect(helpMenu.count == 2)
        do {
            let item = try #require(helpMenu[0] as? UICommand)
            #expect(item.title == "Rules of FreeCell")
            #expect(item.image == UIImage(systemName: "lightbulb"))
            #expect(item.action == #selector(GameViewController.doRules))
        }
        do {
            let item = try #require(helpMenu[1] as? UICommand)
            #expect(item.title == "About TapTapFreeCell")
            #expect(item.image == UIImage(systemName: "questionmark.circle"))
            #expect(item.action == #selector(GameViewController.doHelp))
        }
    }
}
