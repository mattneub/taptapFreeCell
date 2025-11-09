enum GameAction: Equatable {
    case autoplay
    case deal
    case tapped(category: CardView.Category, index: Int)
}
