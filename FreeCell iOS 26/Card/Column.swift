/// A column is one of the eight card columns constituting the layout. An accepted card goes at the
/// bottom of the column, and only the bottom card can be surrendered.
struct Column: Source, Destination, Codable {
    var cards = [Card]()

    var isEmpty: Bool { cards.isEmpty }

    var bottom: Card? { cards.last }

    /// Build and return a copy of the maximum sequence starting at the bottom of the column
    /// and walking up the column.
    var maxMovableSequence: [Card] {
        if isEmpty {
            return []
        }
        if cards.count == 1 {
            return cards
        }
        let cards = Array(cards.reversed())
        for index in 0..<cards.count-1 {
            if !cards[index].canGoOn(cards[index+1]) {
                return Array(cards[...index])
            }
        }
        return cards
    }

    mutating func accept(card: Card) {
        assert(isEmpty || card.canGoOn(bottom!))
        self.cards.append(card)
    }

    mutating func surrenderCard() -> Card {
        assert(!isEmpty)
        return self.cards.removeLast()
    }
}

extension Card {
    /// Whether a card can go on a column.
    func canGoOn(_ column: Column) -> Bool {
        guard let bottom = column.bottom else {
            return true // the column is empty
        }
        return canGoOn(bottom)
    }
}
