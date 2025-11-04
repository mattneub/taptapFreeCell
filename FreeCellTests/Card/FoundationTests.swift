@testable import FreeCell
import Testing

struct FoundationTests {
    @Test("top and isEmpty work correctly")
    func topIsEmpty() {
        var subject = Foundation(suit: .hearts)
        #expect(subject.isEmpty == true)
        #expect(subject.top == nil)
        subject.cards = [.init(rank: .ace, suit: .hearts), .init(rank: .two, suit: .hearts)]
        #expect(subject.isEmpty == false)
        #expect(subject.top == .init(rank: .two, suit: .hearts))
    }

    @Test("accept: appends to cards")
    func accept() {
        var subject = Foundation(suit: .hearts)
        subject.accept(card: .init(rank: .ace, suit: .hearts))
        subject.accept(card: .init(rank: .two, suit: .hearts))
        #expect(subject.cards == [.init(rank: .ace, suit: .hearts), .init(rank: .two, suit: .hearts)])
    }

    @Test("canGoOn: works correctly")
    func canGoOn() {
        do {
            var subject = Foundation(suit: .hearts)
            #expect(Card(rank: .ace, suit: .hearts).canGoOn(subject) == true)
            #expect(Card(rank: .two, suit: .hearts).canGoOn(subject) == false)
            subject.cards = [.init(rank: .ace, suit: .hearts)]
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
        subject[0].cards = [.init(rank: .ace, suit: .hearts)]
        subject[1].cards = [.init(rank: .ace, suit: .spades)]
        #expect(Card(rank: .ace, suit: .clubs).canGoOn(subject) == false)
        #expect(Card(rank: .ace, suit: .spades).canGoOn(subject) == false)
        #expect(Card(rank: .two, suit: .spades).canGoOn(subject) == true)
        #expect(Card(rank: .three, suit: .spades).canGoOn(subject) == false)
    }
}
