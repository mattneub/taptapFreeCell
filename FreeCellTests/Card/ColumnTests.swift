@testable import FreeCell
import Testing

struct ColumnTests {
    @Test("isEmpty and bottom are correct")
    func isEmptyBottom() {
        var subject = Column()
        #expect(subject.isEmpty)
        #expect(subject.bottom == nil)
        subject.cards = [
            .init(rank: .king, suit: .hearts),
            .init(rank: .ten, suit: .hearts),
            .init(rank: .nine, suit: .clubs)
        ]
        #expect(!subject.isEmpty)
        #expect(subject.bottom == .init(rank: .nine, suit: .clubs))
    }

    @Test("maxMovableSequence: gives the right answer")
    func maxMovableSequence() {
        var subject = Column()
        do { // no cards
            #expect(subject.maxMovableSequence == [])
        }
        do { // one card
            subject.cards = [.init(rank: .king, suit: .hearts)]
            #expect(subject.maxMovableSequence == [.init(rank: .king, suit: .hearts)])
            #expect(subject.cards == [.init(rank: .king, suit: .hearts)]) // cards untouched
        }
        do { // two cards, no sequence
            subject.cards = [
                .init(rank: .king, suit: .hearts),
                .init(rank: .ten, suit: .hearts),
            ]
            #expect(subject.maxMovableSequence == [.init(rank: .ten, suit: .hearts)])
            #expect(subject.cards == [
                .init(rank: .king, suit: .hearts),
                .init(rank: .ten, suit: .hearts),
            ])
        }
        do { // two cards, whole thing is a sequence
            subject.cards = [
                .init(rank: .ten, suit: .hearts),
                .init(rank: .nine, suit: .clubs)
            ]
            #expect(subject.maxMovableSequence == [
                .init(rank: .nine, suit: .clubs),
                .init(rank: .ten, suit: .hearts),
            ])
            #expect(subject.cards == [
                .init(rank: .ten, suit: .hearts),
                .init(rank: .nine, suit: .clubs)
            ])
        }
        do { // three cards, sequence of two
            subject.cards = [
                .init(rank: .king, suit: .hearts),
                .init(rank: .ten, suit: .hearts),
                .init(rank: .nine, suit: .clubs)
            ]
            #expect(subject.maxMovableSequence == [
                .init(rank: .nine, suit: .clubs),
                .init(rank: .ten, suit: .hearts),
            ])
            #expect(subject.cards == [
                .init(rank: .king, suit: .hearts),
                .init(rank: .ten, suit: .hearts),
                .init(rank: .nine, suit: .clubs)
            ])
        }
        do { // three cards, whole things is a sequence
            subject.cards = [
                .init(rank: .jack, suit: .spades),
                .init(rank: .ten, suit: .hearts),
                .init(rank: .nine, suit: .clubs)
            ]
            #expect(subject.maxMovableSequence == [
                .init(rank: .nine, suit: .clubs),
                .init(rank: .ten, suit: .hearts),
                .init(rank: .jack, suit: .spades),
            ])
            #expect(subject.cards == [
                .init(rank: .jack, suit: .spades),
                .init(rank: .ten, suit: .hearts),
                .init(rank: .nine, suit: .clubs)
            ])
        }
    }

    @Test("accept: behaves as expected")
    func accept() {
        var subject = Column()
        subject.cards = [
            .init(rank: .king, suit: .hearts),
            .init(rank: .ten, suit: .hearts),
        ]
        subject.accept(card: .init(rank: .nine, suit: .clubs))
        #expect(subject.cards == [
            .init(rank: .king, suit: .hearts),
            .init(rank: .ten, suit: .hearts),
            .init(rank: .nine, suit: .clubs)
        ])
    }

    @Test("surrender: behaves as expected")
    func surrender() {
        var subject = Column()
        subject.cards = [
            .init(rank: .king, suit: .hearts),
            .init(rank: .ten, suit: .hearts),
        ]
        let result = subject.surrenderCard()
        #expect(result == .init(rank: .ten, suit: .hearts))
        #expect(subject.cards == [.init(rank: .king, suit: .hearts)])
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
                .init(rank: .king, suit: .hearts),
            ]
            #expect(card.canGoOn(subject) == false)
        }
        do {
            subject.cards = [
                .init(rank: .king, suit: .hearts),
                .init(rank: .ten, suit: .hearts),
            ]
            #expect(card.canGoOn(subject) == true)
        }
    }
}
