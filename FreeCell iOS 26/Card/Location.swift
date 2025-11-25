/// A Location is a place within the Layout — the thing that a CardView visibly represents, the
/// thing that is a Source and/or Destination for the moving of Cards.
struct Location: Equatable, Hashable {
    let category: Category
    let index: Int

    /// Single character of the standard two-character notation — attributed to Andrey Tsouladze,
    /// though I have not found any historical support for this attribution apart from e.g.
    /// <https://www.solitairelaboratory.com/solutioncatalog.html>.
    /// In other words, the source Location standard notation plus the destination Location
    /// standard notation is the standard notation for a move.
    var standardNotation: String {
        switch category {
        case .foundation: "h"
        case .freeCell: String(Unicode.Scalar(index + 97) ?? Unicode.Scalar("a"))
        case .column: String(index + 1)
        }
    }

    enum Category: Equatable {
        case column
        case freeCell
        case foundation
    }
}
