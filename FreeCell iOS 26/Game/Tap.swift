/// A Tap is the bridge between the visible interface world of card views and the behind the
/// scenes world of the game processor and layout. When the user taps a card view, it reports
/// this as a Tap object.
struct Tap: Equatable {
    let category: CardView.Category
    let index: Int
}
