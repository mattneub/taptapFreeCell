@testable import FreeCell
import Testing

struct SuitTests {
    @Test("string raw values are correct")
    func stringRawValues() {
        do {
            let subject = Suit.hearts
            #expect(subject.rawValue == "H")
        }
        do {
            let subject = Suit.diamonds
            #expect(subject.rawValue == "D")
        }
        do {
            let subject = Suit.spades
            #expect(subject.rawValue == "S")
        }
        do {
            let subject = Suit.clubs
            #expect(subject.rawValue == "C")
        }
    }

    @Test("colors are correct")
    func colors() {
        do {
            let result = Suit.hearts.color
            #expect(result == .red)
        }
        do {
            let result = Suit.diamonds.color
            #expect(result == .red)
        }
        do {
            let result = Suit.spades.color
            #expect(result == .black)
        }
        do {
            let result = Suit.clubs.color
            #expect(result == .black)
        }
    }

    @Test("suits of opposite color are correct")
    func suitsOfOppositeColor() {
        do {
            let result = Set(Suit.hearts.suitsOfOppositeColor)
            #expect(result == [.spades, .clubs])
        }
        do {
            let result = Set(Suit.diamonds.suitsOfOppositeColor)
            #expect(result == [.spades, .clubs])
        }
        do {
            let result = Set(Suit.spades.suitsOfOppositeColor)
            #expect(result == [.hearts, .diamonds])
        }
        do {
            let result = Set(Suit.clubs.suitsOfOppositeColor)
            #expect(result == [.hearts, .diamonds])
        }
    }

    @Test("other suit of same color is correct")
    func otherSuit() {
        do {
            let result = Suit.hearts.otherSuitOfSameColor
            #expect(result == .diamonds)
        }
        do {
            let result = Suit.diamonds.otherSuitOfSameColor
            #expect(result == .hearts)
        }
        do {
            let result = Suit.spades.otherSuitOfSameColor
            #expect(result == .clubs)
        }
        do {
            let result = Suit.clubs.otherSuitOfSameColor
            #expect(result == .spades)
        }
    }

    @Test("microsoft cases is correct")
    func microsoftCases() {
        let result = Suit.microsoftCases
        #expect(result == [.clubs, .diamonds, .hearts, .spades])
    }

    @Test("description is correct")
    func description() {
        let result = Suit.microsoftCases.map { $0.description }
        #expect(result == ["C", "D", "H", "S"])
    }

    @Test("reverse description is correct")
    func reverseDescription() {
        let result = ["C", "D", "H", "S"].map(Suit.init(description:))
        #expect(result == [.clubs, .diamonds, .hearts, .spades])
    }
}
