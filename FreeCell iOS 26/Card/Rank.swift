nonisolated enum Rank : Int, CaseIterable, CustomStringConvertible, Codable {
    // TODO: It was important that ace be first in my original, keep an eye on this
    // Plus king was next, but why do I not just let the numbering be automatic?
    case ace = 1
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case ten
    case jack
    case queen
    case king

    static var microsoftCases: [Rank] {
        allCases
    }

    var description: String {
        let specials: [Rank: String] = [.ace: "A", .king: "K", .queen: "Q", .jack: "J", .ten: "T"]
        return specials[self] ?? String(rawValue)
    }

    /// Reverse description, i.e. one-character description to rank
    init?(description character: Character) {
        if let integer = Int(String(character)) {
            self.init(rawValue: integer)
        } else {
            let specials: [String: Rank] = ["A": .ace, "K": .king, "Q": .queen, "J": .jack, "T": .ten]
            if let rank = specials[String(character)] {
                self = rank
            } else {
                return nil // shouldn't happen
            }
        }
    }
}
