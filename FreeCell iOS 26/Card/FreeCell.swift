/// A freecell can hold at most one card.
struct FreeCell : Source, Destination, CustomStringConvertible, Codable {
    var cards = [Card]()

    var card: Card? {
        cards.first
    }

    var isEmpty: Bool {
        self.cards.isEmpty
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
        self.cards = [card]
    }

    mutating func surrenderCard() -> Card {
        assert(!self.isEmpty)
        let card = self.card
        self.cards = []
        return if let card {
            card
        } else {
            fatalError("this cannot happen")
        }
    }
}
