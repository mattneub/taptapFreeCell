/// A freecell can hold at most one card.
struct FreeCell : Source, Destination, CustomStringConvertible {
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

    /*
     In earlier versions of the app, FreeCell had a `card` stored property and no `cards` property.
     I changed that because life is a lot easier when all three categories have `cards`. But
     because FreeCell objects are saved into the stats dictionary file, we have to convert between
     the older (on disk) property and the newer (in the running app) property.
     */

    enum CodingKeys: String, CodingKey {
        case card // this is what exists in the encoded version; it is effectively an Optional
    }
}

/// Extension that makes our FreeCell type Codable. The use of an extension here is not just
/// for neatness; we need to do this so as not to destroy the automatic `init()` initializer.
extension FreeCell: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let card = try container.decodeIfPresent(Card.self, forKey: .card) {
            self.cards = [card]
        } else {
            self.cards = []
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.card, forKey: .card)
    }
}
