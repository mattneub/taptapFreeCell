
struct Card : Equatable, Hashable, CustomStringConvertible, Codable {
    let rank: Rank
    let suit: Suit

    init(rank: Rank, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }

    init(microsoftIndex index: Int) {
        self.init(
            rank: Rank.microsoftCases[index / 4],
            suit: Suit.microsoftCases[index % 4]
        )
    }

    var description: String {
        String(describing: rank) + String(describing: suit)
    }

    init?(description string: String) {
        let chars = Array(string)
        guard chars.count == 2 else {
            return nil
        }
        guard let rank = Rank(description: chars[0]) else {
            return nil
        }
        guard let suit = Suit(description: chars[1]) else {
            return nil
        }
        self.init(rank: rank, suit: suit)
    }

    /// The fundamental rule of play! In a column, a card can go on another if the other is of
    /// the other color and is one higher in rank.
    func canGoOn(_ other: Card) -> Bool {
        other.suit.color != suit.color && other.rank.rawValue == rank.rawValue + 1
    }

    enum Color {
        case red
        case black
    }
}
