@testable import FreeCell
import Testing

struct FreeCellTests {
    @Test("card and isEmpty work")
    func cardAndIsEmpty() {
        var subject = FreeCell()
        #expect(subject.isEmpty == true)
        #expect(subject.card == nil)
        subject.cards = [Card(rank: .jack, suit: .hearts)]
        #expect(subject.isEmpty == false)
        #expect(subject.card == Card(rank: .jack, suit: .hearts))
    }

    @Test("description works")
    func description() {
        var subject = FreeCell()
        #expect(subject.description == "XX")
        subject.cards = [Card(rank: .jack, suit: .hearts)]
        #expect(subject.description == "JH")
    }

    @Test("accept works")
    func accept() {
        var subject = FreeCell()
        subject.accept(card: Card(rank: .jack, suit: .hearts))
        #expect(subject.card == Card(rank: .jack, suit: .hearts))
    }

    @Test("surrender works")
    func surrender() {
        var subject = FreeCell()
        subject.cards = [Card(rank: .jack, suit: .hearts)]
        let result = subject.surrenderCard()
        #expect(subject.card == nil)
        #expect(result == Card(rank: .jack, suit: .hearts))
    }
}
