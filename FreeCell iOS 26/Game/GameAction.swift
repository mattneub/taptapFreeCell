import UIKit

enum GameAction: Equatable {
    case autoplay
    case deal
    case didInitialLayout
    case hint
    case longPress(Location, Int)
    case longPressEnded
    case redo
    case redoAll
    case resized
    case showHelp
    case showImportExport
    case showMicrosoft(SourceItemWrapper)
    case showPrefs
    case showRules
    case showStats
    case tapBackground
    case tapped(Location)
    case undo
    case undoAll
}

/// Sneaky trick to allow a source item to be passed in a case's associated value while
/// maintaining our synthesized equatable conformance.
struct SourceItemWrapper: Equatable {
    let sourceItem: any UIPopoverPresentationControllerSourceItem
    static func ==(_: SourceItemWrapper, _: SourceItemWrapper) -> Bool { true }
}
