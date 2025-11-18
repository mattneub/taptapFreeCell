@testable import FreeCell
import Testing

struct ColumnTests {
    @Test("isEmpty and card are correct")
    func isEmptyAndCard() {
        var subject = Column()
        #expect(subject.isEmpty)
        #expect(subject.card == nil)
        subject.cards = [
            Card(rank: .king, suit: .hearts),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs)
        ]
        #expect(!subject.isEmpty)
        #expect(subject.card == Card(rank: .nine, suit: .clubs))
    }

    @Test("maxMovableSequence: gives the right answer")
    func maxMovableSequence() {
        var subject = Column()
        do { // no cards
            #expect(subject.maxMovableSequence == [])
        }
        do { // one card
            subject.cards = [Card(rank: .king, suit: .hearts)]
            #expect(subject.maxMovableSequence == [Card(rank: .king, suit: .hearts)])
            #expect(subject.cards == [Card(rank: .king, suit: .hearts)]) // cards untouched
        }
        do { // two cards, no sequence
            subject.cards = [
                Card(rank: .king, suit: .hearts),
                Card(rank: .ten, suit: .hearts),
            ]
            #expect(subject.maxMovableSequence == [Card(rank: .ten, suit: .hearts)])
            #expect(subject.cards == [
                Card(rank: .king, suit: .hearts),
                Card(rank: .ten, suit: .hearts),
            ])
        }
        do { // two cards, whole thing is a sequence
            subject.cards = [
                Card(rank: .ten, suit: .hearts),
                Card(rank: .nine, suit: .clubs)
            ]
            #expect(subject.maxMovableSequence == [
                Card(rank: .nine, suit: .clubs),
                Card(rank: .ten, suit: .hearts),
            ])
            #expect(subject.cards == [
                Card(rank: .ten, suit: .hearts),
                Card(rank: .nine, suit: .clubs)
            ])
        }
        do { // three cards, sequence of two
            subject.cards = [
                Card(rank: .king, suit: .hearts),
                Card(rank: .ten, suit: .hearts),
                Card(rank: .nine, suit: .clubs)
            ]
            #expect(subject.maxMovableSequence == [
                Card(rank: .nine, suit: .clubs),
                Card(rank: .ten, suit: .hearts),
            ])
            #expect(subject.cards == [
                Card(rank: .king, suit: .hearts),
                Card(rank: .ten, suit: .hearts),
                Card(rank: .nine, suit: .clubs)
            ])
        }
        do { // three cards, whole things is a sequence
            subject.cards = [
                Card(rank: .jack, suit: .spades),
                Card(rank: .ten, suit: .hearts),
                Card(rank: .nine, suit: .clubs)
            ]
            #expect(subject.maxMovableSequence == [
                Card(rank: .nine, suit: .clubs),
                Card(rank: .ten, suit: .hearts),
                Card(rank: .jack, suit: .spades),
            ])
            #expect(subject.cards == [
                Card(rank: .jack, suit: .spades),
                Card(rank: .ten, suit: .hearts),
                Card(rank: .nine, suit: .clubs)
            ])
        }
    }

    @Test("accept: behaves as expected")
    func accept() {
        var subject = Column()
        subject.cards = [
            Card(rank: .king, suit: .hearts),
            Card(rank: .ten, suit: .hearts),
        ]
        subject.accept(card: Card(rank: .nine, suit: .clubs))
        #expect(subject.cards == [
            Card(rank: .king, suit: .hearts),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs)
        ])
    }

    @Test("surrender: behaves as expected")
    func surrender() {
        var subject = Column()
        subject.cards = [
            Card(rank: .king, suit: .hearts),
            Card(rank: .ten, suit: .hearts),
        ]
        let result = subject.surrenderCard()
        #expect(result == Card(rank: .ten, suit: .hearts))
        #expect(subject.cards == [Card(rank: .king, suit: .hearts)])
    }

    @Test("canGoOn: behaves correctly")
    func canGoOn() {
        var subject = Column()
        let card = Card(rank: .nine, suit: .spades)
        do {
            #expect(card.canGoOn(subject) == true)
        }
        do {
            subject.cards = [
                Card(rank: .king, suit: .hearts),
            ]
            #expect(card.canGoOn(subject) == false)
        }
        do {
            subject.cards = [
                Card(rank: .king, suit: .hearts),
                Card(rank: .ten, suit: .hearts),
            ]
            #expect(card.canGoOn(subject) == true)
        }
    }
}
