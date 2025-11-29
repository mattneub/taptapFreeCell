/// The four ways of sorting the full data; the Int value is the segment index.
enum StatsSorting: Int, CaseIterable {
    case date = 0
    case time
    case moves
    case won
    case microsoft // placeholder for when we are filtered for microsoft

    /// Titles for the segmented control.
    var text: String {
        switch self {
        case .date: "Date"
        case .time: "Time"
        case .moves: "Moves"
        case .won: "Won"
        case .microsoft: "" // no title; if filtered for microsoft, we are sorted for microsoft
        }
    }
}
