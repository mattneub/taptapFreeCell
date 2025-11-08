import Foundation

/// The full deck of cards. The reason this can be a struct is that we only ever deal out _all_
/// the cards, once, and then we're done with it, so there is no need to keep a master reference.
struct Deck: CustomStringConvertible, Codable, Equatable {
    var cards = [Card]()

    var isEmpty: Bool { cards.isEmpty }

    init() {
        for rank in Rank.allCases {
            for suit in Suit.allCases {
                cards.append(Card(rank: rank, suit: suit))
            }
        }
    }

    init(microsoftDealNumber:Int) {
        for i in (0..<52).reversed() {
            self.cards.append(Card(microsoftIndex: i))
        }
        struct MicrosoftLinearCongruentialGenerator {
            var seed : Int
            mutating func next() -> Int {
                self.seed = (self.seed * 214013 + 2531011) % (Int(Int32.max)+1)
                return self.seed >> 16
            }
        }
        var r = MicrosoftLinearCongruentialGenerator(seed: microsoftDealNumber)
        for i in 0..<51 {
            self.cards.swapAt(i, 51-r.next()%(52-i))
        }
    }

    mutating func shuffle() {
        self.cards.shuffle()
    }

    var description: String {
        return String(describing: cards)
    }

    var dealDescription: String { // as if dealt into 8 columns
        var output = ""
        for (index, card) in cards.enumerated() {
            output.write(String(describing: card))
            output.write(index % 8 == 7 ? "\n" : " ")
        }
        return output.trimmingWhitespacesFromLineEnds // NB this is different from before
    }

    mutating func deal() -> Card {
        assert(!cards.isEmpty)
        return self.cards.removeFirst()
    }
}
