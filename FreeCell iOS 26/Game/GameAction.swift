enum GameAction: Equatable {
    case autoplay
    case deal
    case hint
    case tapBackground
    case tapped(Location)
}
