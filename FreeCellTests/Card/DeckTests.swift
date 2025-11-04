@testable import FreeCell
import Testing

struct DeckTests {
    @Test("initialize: makes the deck of 52 cards")
    func initialize() {
        let subject = Deck()
        #expect(Set(subject.cards).count == 52)
    }

    @Test("Microsoft deal 1 is correct (and also test dealDescription)")
    func testDeal1() {
        let expected = """
        JD 2D 9H JC 5D 7H 7C 5H
        KD KC 9S 5S AD QC KH 3H
        2S KS 9D QD JS AS AH 3C
        4C 5C TS QH 4H AC 4D 7S
        3S TD 4S TH 8H 2C JH 7D
        6D 8S 8D QS 6C 3D 8C TC
        6S 9C 2H 6H 
        """
        let subject = Deck(microsoftDealNumber: 1)
        #expect(subject.dealDescription == expected)
    }

    @Test("Microsoft deal 617 is correct (and also test dealDescription)")
    func testDeal617() {
        let expected = """
        7D AD 5C 3S 5S 8C 2D AH
        TD 7S QD AC 6D 8H AS KH
        TH QC 3H 9D 6S 8D 3D TC
        KD 5H 9S 3C 8S 7H 4D JS
        4C QS 9C 9H 7C 6H 2C 2S
        4S TS 2H 5D JC 6C JH QH
        JD KS KC 4H 
        """
        let subject = Deck(microsoftDealNumber: 617)
        #expect(subject.dealDescription == expected)
    }

    @Test("Microsoft deal 999999 is correct (and also test dealDescription)")
    func testDeal999999() {
        let expected = """
        AH 9S 3D 6C 8D 8H QS TS
        KD 3C 2D 6D 5H QD 2S 4D
        9D 3S 6H 9H QC JH AS JS
        3H 7H 2H 7S JC 5D TD TH
        6S 4S 9C 5C 8C 8S 4C TC
        7C AC KH 2C 5S KS AD 4H
        QH KC JD 7D 
        """
        let subject = Deck(microsoftDealNumber: 999999)
        #expect(subject.dealDescription == expected)
    }

    @Test("shuffle: shuffles")
    func shuffle() {
        var subject = Deck()
        let unshuffled = Deck()
        #expect(subject == unshuffled)
        subject.shuffle()
        #expect(subject != unshuffled)
        #expect(Set(subject.cards) == Set(unshuffled.cards))
    }

    @Test("deal: deals from the front of the deck")
    func deal() {
        var subject = Deck()
        subject.cards = [.init(rank: .jack, suit: .hearts), .init(rank: .queen, suit: .clubs)]
        let result = subject.deal()
        #expect(result == .init(rank: .jack, suit: .hearts))
        #expect(subject.cards == [.init(rank: .queen, suit: .clubs)])
    }
}
