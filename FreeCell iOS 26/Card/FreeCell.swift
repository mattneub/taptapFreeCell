/// A freecell can hold at most one card.
struct FreeCell : Source, Destination, CustomStringConvertible, Codable {
    var card: Card?

    var isEmpty: Bool {
        self.card == nil
    }

    var description: String {
        return if let card {
            String(describing: card)
        } else {
            "XX"
        }
    }

    mutating func accept(card: Card) {
        assert(self.isEmpty)
        self.card = card
    }

    mutating func surrenderCard() -> Card {
        assert(!self.isEmpty)
        let card = self.card
        self.card = nil
        return if let card {
            card
        } else {
            fatalError("this cannot happen")
        }
    }
}
