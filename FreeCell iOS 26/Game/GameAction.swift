enum GameAction: Equatable {
    case autoplay
    case deal
    case didInitialLayout
    case hint
    case longPress(Location, Int)
    case longPressEnded
    case redo
    case redoAll
    case showHelp
    case showRules
    case showStats
    case tapBackground
    case tapped(Location)
    case undo
    case undoAll
}
