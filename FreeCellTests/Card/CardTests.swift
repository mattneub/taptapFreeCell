@testable import TTFreeCell
import Testing

private struct CardTests {
    @Test("initialize from rank and suit")
    func initializeRankSuit() {
        let result = Card(rank: .jack, suit: .hearts)
        #expect(result.rank == .jack)
        #expect(result.suit == .hearts)
    }

    @Test("description is correct")
    func description() {
        do {
            let result = Card(rank: .jack, suit: .hearts).description
            #expect(result == "JH")
        }
        do {
            let result = Card(rank: .two, suit: .diamonds).description
            #expect(result == "2D")
        }
        do {
            let result = Card(rank: .ace, suit: .clubs).description
            #expect(result == "AC")
        }
        // okay, I'm convinced
    }

    @Test("initialize from microsoft index")
    func initializeMicrosoftIndex() {
        do {
            let result = Card(microsoftIndex: 0)
            #expect(result.description == "AC")
        }
        do {
            let result = Card(microsoftIndex: 1)
            #expect(result.description == "AD")
        }
        do {
            let result = Card(microsoftIndex: 2)
            #expect(result.description == "AH")
        }
        do {
            let result = Card(microsoftIndex: 3)
            #expect(result.description == "AS")
        }
        do {
            let result = Card(microsoftIndex: 4)
            #expect(result.description == "2C")
        }
        // okay I see the pattern
        do {
            let result = Card(microsoftIndex: 51)
            #expect(result.description == "KS")
        }
    }

    @Test("reverse description works")
    func reverseDescription() {
        do {
            let result = Card(description: "AC")
            #expect(result == Card(rank: .ace, suit: .clubs))
        }
        do {
            let result = Card(description: "2H")
            #expect(result == Card(rank: .two, suit: .hearts))
        }
        do {
            let result = Card(description: "3D")
            #expect(result == Card(rank: .three, suit: .diamonds))
        }
        do {
            let result = Card(description: "4S")
            #expect(result == Card(rank: .four, suit: .spades))
        }
        do {
            let result = Card(description: "TH")
            #expect(result == Card(rank: .ten, suit: .hearts))
        }
        do {
            let result = Card(description: "JD")
            #expect(result == Card(rank: .jack, suit: .diamonds))
        }
        // okay I'm convinced; try some bad ones
        do {
            let result = Card(description: "J")
            #expect(result == nil)
        }
        do {
            let result = Card(description: "JHH")
            #expect(result == nil)
        }
        do {
            let result = Card(description: "22")
            #expect(result == nil)
        }
    }

    @Test("canGoOn: gives the right answer")
    func canGoOn() {
        do {
            let card = Card(rank: .ten, suit: .hearts)
            let other = Card(rank: .jack, suit: .clubs)
            #expect(card.canGoOn(other) == true)
        }
        do {
            let card = Card(rank: .ten, suit: .hearts)
            let other = Card(rank: .jack, suit: .spades)
            #expect(card.canGoOn(other) == true)
        }
        do {
            let card = Card(rank: .ten, suit: .hearts)
            let other = Card(rank: .jack, suit: .diamonds)
            #expect(card.canGoOn(other) == false)
        }
        do {
            let card = Card(rank: .ten, suit: .hearts)
            let other = Card(rank: .jack, suit: .hearts)
            #expect(card.canGoOn(other) == false)
        }
        do {
            let card = Card(rank: .ten, suit: .hearts)
            let other = Card(rank: .queen, suit: .clubs)
            #expect(card.canGoOn(other) == false)
        }
        do {
            let card = Card(rank: .ten, suit: .hearts)
            let other = Card(rank: .nine, suit: .clubs)
            #expect(card.canGoOn(other) == false)
        }
        // okay, good enough for me
    }
}
