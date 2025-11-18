enum GameAction: Equatable {
    case autoplay
    case deal
    case hint
    case longPress(Location, Int)
    case longPressEnded
    case redo
    case redoAll
    case tapBackground
    case tapped(Location)
    case undo
    case undoAll
}
