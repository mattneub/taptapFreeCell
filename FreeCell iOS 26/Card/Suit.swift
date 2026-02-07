nonisolated enum Suit: String, CustomStringConvertible, CaseIterable, Codable {
    case hearts = "H"
    case diamonds = "D"
    case spades = "S"
    case clubs = "C"

    var color: Card.Color {
        (self == .hearts || self == .diamonds) ? .red : .black
    }

    var suitsOfOppositeColor: [Suit] {
        Suit.allCases.filter {
            $0.color != self.color
        }
    }

    var otherSuitOfSameColor: Suit {
        Suit.allCases.first {
            $0.color == self.color && $0 != self
        } ?? self // won't happen
    }

    // microsoft order is clubs = "C", diamonds = "D", hearts = "H", spades = "S"
    static var microsoftCases: [Suit] {
        [clubs, diamonds, hearts, spades]
    }

    static var foundationOrder: [Suit] {
        [spades, hearts, clubs, diamonds]
    }

    var foundationOrderIndex: Int {
        switch self {
        case .spades: 0
        case .hearts: 1
        case .clubs: 2
        case .diamonds: 3
        }
    }

    var description: String {
        return self.rawValue
    }

    /// Reverse description, i.e. one-character description to suit
    init?(description character: Character) {
        self.init(rawValue: String(character))
    }
}

