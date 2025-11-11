/// A foundation consists of all cards of the same suit in order. Only an ace can go in
/// its suit's empty foundation, only the two can go on an ace, and so on.
struct Foundation: Destination, Codable {
    var cards = [Card]()

    var card: Card? {
        cards.last
    }

    let suit : Suit

    var isEmpty: Bool {
        cards.isEmpty
    }

    mutating func accept(card: Card) {
        assert(card.canGoOn(self))
        cards.append(card)
    }
}

/// Whether a card can go on a foundation pile, or _any_ foundation pile
extension Card {
    func canGoOn(_ foundation: Foundation) -> Bool {
        suit == foundation.suit && (
            (
                foundation.isEmpty && rank == .ace ||
                foundation.card?.rank.rawValue == rank.rawValue - 1
            )
        )
    }

    func canGoOn(_ foundations: [Foundation]) -> Bool {
        foundations.first(where: { canGoOn($0) }) != nil
    }
}

/// Extension that lets an _array_ of foundations accept a card (into the right foundation).
/// In practice this makes it a lot easier to throw a card at the layout foundations.
extension Array where Element == Foundation {
    mutating func accept(card: Card) {
        self.modifyEach { foundation in
            if card.canGoOn(foundation) {
                foundation.accept(card: card)
                return
            }
        }
    }
}

/// Trick to satisfy behind-the-scenes mumbo-jumbo.
/// If this causes the app not to work, we will have to rename the Foundation struct. :(
extension Foundation {
    final class Bundle {
        init(for what: AnyClass) {}
    }
}
