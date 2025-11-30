@testable import TTFreeCell
import Testing

private struct RankTests {
    @Test("integer raw values are correct")
    func integerRawValues() {
        do {
            let subject = Rank.ace
            #expect(subject.rawValue == 1)
        }
        do {
            let subject = Rank.two
            #expect(subject.rawValue == 2)
        }
        do {
            let subject = Rank.three
            #expect(subject.rawValue == 3)
        }
        do {
            let subject = Rank.four
            #expect(subject.rawValue == 4)
        }
        do {
            let subject = Rank.five
            #expect(subject.rawValue == 5)
        }
        do {
            let subject = Rank.six
            #expect(subject.rawValue == 6)
        }
        do {
            let subject = Rank.seven
            #expect(subject.rawValue == 7)
        }
        do {
            let subject = Rank.eight
            #expect(subject.rawValue == 8)
        }
        do {
            let subject = Rank.nine
            #expect(subject.rawValue == 9)
        }
        do {
            let subject = Rank.ten
            #expect(subject.rawValue == 10)
        }
        do {
            let subject = Rank.jack
            #expect(subject.rawValue == 11)
        }
        do {
            let subject = Rank.queen
            #expect(subject.rawValue == 12)
        }
        do {
            let subject = Rank.king
            #expect(subject.rawValue == 13)
        }
    }

    @Test("microsoft cases is correct")
    func microsoftCases() {
        let result = Rank.microsoftCases
        #expect(result == [
            .ace, .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .jack, .queen, .king
        ])
    }

    @Test("description is correct")
    func description() {
        let result = Rank.allCases.map { $0.description }
        #expect(result == ["A", "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K"])
    }

    @Test("reverse description is correct")
    func reverseDescription() {
        let result = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K"].map(Rank.init(description:))
        #expect(result == [
            .ace, .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .jack, .queen, .king
        ])
    }

    
}
