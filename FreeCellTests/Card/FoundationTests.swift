@testable import TTFreeCell
import Testing

struct FoundationTests {
    @Test("card and isEmpty work correctly")
    func cardAndIsEmpty() {
        var subject = Foundation(suit: .hearts)
        #expect(subject.isEmpty == true)
        #expect(subject.card == nil)
        subject.cards = [Card(rank: .ace, suit: .hearts), Card(rank: .two, suit: .hearts)]
        #expect(subject.isEmpty == false)
        #expect(subject.card == Card(rank: .two, suit: .hearts))
    }

    @Test("accept: appends to cards")
    func accept() {
        var subject = Foundation(suit: .hearts)
        subject.accept(card: Card(rank: .ace, suit: .hearts))
        subject.accept(card: Card(rank: .two, suit: .hearts))
        #expect(subject.cards == [Card(rank: .ace, suit: .hearts), Card(rank: .two, suit: .hearts)])
    }

    @Test("canGoOn: works correctly")
    func canGoOn() {
        do {
            var subject = Foundation(suit: .hearts)
            #expect(Card(rank: .ace, suit: .hearts).canGoOn(subject) == true)
            #expect(Card(rank: .two, suit: .hearts).canGoOn(subject) == false)
            subject.cards = [Card(rank: .ace, suit: .hearts)]
            #expect(Card(rank: .two, suit: .hearts).canGoOn(subject) == true)
            #expect(Card(rank: .three, suit: .hearts).canGoOn(subject) == false)
        }
        do {
            let subject = Foundation(suit: .diamonds)
            #expect(Card(rank: .ace, suit: .hearts).canGoOn(subject) == false)
        }
    }

    @Test("canGoOn: foundation array works correctly")
    func canGoOnArray() {
        var subject = [Foundation(suit: .hearts), Foundation(suit: .spades)]
        #expect(Card(rank: .ace, suit: .clubs).canGoOn(subject) == false)
        #expect(Card(rank: .ace, suit: .spades).canGoOn(subject) == true)
        subject[0].cards = [Card(rank: .ace, suit: .hearts)]
        subject[1].cards = [Card(rank: .ace, suit: .spades)]
        #expect(Card(rank: .ace, suit: .clubs).canGoOn(subject) == false)
        #expect(Card(rank: .ace, suit: .spades).canGoOn(subject) == false)
        #expect(Card(rank: .two, suit: .spades).canGoOn(subject) == true)
        #expect(Card(rank: .three, suit: .spades).canGoOn(subject) == false)
    }

    @Test("accept: foundation array works correctly")
    func acceptArray() {
        var subject = [Foundation(suit: .hearts), Foundation(suit: .spades), Foundation(suit: .clubs)]
        subject.accept(card: Card(rank: .ace, suit: .diamonds))
        #expect(subject.allSatisfy { $0.isEmpty }) // didn't go on any of them
        subject.accept(card: Card(rank: .ace, suit: .spades))
        #expect(subject[0].isEmpty)
        #expect(subject[1].cards == [Card(rank: .ace, suit: .spades)])
        #expect(subject[2].isEmpty)
        subject.accept(card: Card(rank: .two, suit: .spades))
        #expect(subject[0].isEmpty)
        #expect(subject[1].cards == [Card(rank: .ace, suit: .spades), Card(rank: .two, suit: .spades)])
        #expect(subject[2].isEmpty)
        subject.accept(card: Card(rank: .two, suit: .clubs))
        #expect(subject[0].isEmpty)
        #expect(subject[1].cards == [Card(rank: .ace, suit: .spades), Card(rank: .two, suit: .spades)])
        #expect(subject[2].isEmpty)
    }
}
