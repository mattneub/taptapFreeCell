@testable import FreeCell
import Testing

struct FreeCellTests {
    @Test("isEmpty works")
    func isEmpty() {
        var subject = FreeCell()
        #expect(subject.isEmpty == true)
        subject.card = .init(rank: .jack, suit: .hearts)
        #expect(subject.isEmpty == false)
    }

    @Test("description works")
    func description() {
        var subject = FreeCell()
        #expect(subject.description == "XX")
        subject.card = .init(rank: .jack, suit: .hearts)
        #expect(subject.description == "JH")
    }

    @Test("accept works")
    func accept() {
        var subject = FreeCell()
        subject.accept(card: .init(rank: .jack, suit: .hearts))
        #expect(subject.card == .init(rank: .jack, suit: .hearts))
    }

    @Test("surrender works")
    func surrender() {
        var subject = FreeCell()
        subject.card = .init(rank: .jack, suit: .hearts)
        let result = subject.surrenderCard()
        #expect(subject.card == nil)
        #expect(result == .init(rank: .jack, suit: .hearts))
    }
}
