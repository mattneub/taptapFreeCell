import Foundation

struct Deck: CustomStringConvertible, Codable, Equatable {
    var cards = [Card]()

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
        var s = ""
        for (index, card) in cards.enumerated() {
            s.write(String(describing: card))
            s.write(index % 8 == 7 ? "\n" : " ")
        }
        return s
    }

    mutating func deal() -> Card {
        assert(!cards.isEmpty)
        return self.cards.removeFirst()
    }
}
