/// A Location is a place within the Layout — the thing that a CardView visibly represents, the
/// thing that is a Source and/or Destination for the moving of Cards.
struct Location: Equatable {
    let category: Category
    let index: Int

    enum Category: Equatable {
        case column
        case freeCell
        case foundation
    }
}
