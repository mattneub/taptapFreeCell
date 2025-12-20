@testable import TTFreeCell
import Testing

private struct LayoutTests {
    @Test("basic layout structure is correct")
    func initialize() {
        let subject = Layout()
        #expect(subject.foundations.count == 4)
        #expect(subject.foundations.map {$0.suit} == [.spades, .hearts, .clubs, .diamonds])
        #expect(subject.freeCells.count == 4)
        #expect(subject.columns.count == 8)
    }

    @Test("indexOfFoundation is correct")
    func indexOfFoundation() {
        let subject = Layout()
        var result = subject.indexOfFoundation(for: .spades)
        #expect(result == 0)
        #expect(subject.foundations[result].suit == .spades)
        result = subject.indexOfFoundation(for: .hearts)
        #expect(result == 1)
        #expect(subject.foundations[result].suit == .hearts)
        result = subject.indexOfFoundation(for: .clubs)
        #expect(result == 2)
        #expect(subject.foundations[result].suit == .clubs)
        result = subject.indexOfFoundation(for: .diamonds)
        #expect(result == 3)
        #expect(subject.foundations[result].suit == .diamonds)
    }

    @Test("foundationForSuit is correct")
    func foundationForSuit() {
        let subject = Layout()
        var result = subject.foundation(for: .spades)
        #expect(result.suit == .spades)
        result = subject.foundation(for: .hearts)
        #expect(result.suit == .hearts)
        result = subject.foundation(for: .clubs)
        #expect(result.suit == .clubs)
        result = subject.foundation(for: .diamonds)
        #expect(result.suit == .diamonds)
    }

    @Test("empty free cells works correctly")
    func emptyFreeCells() {
        var subject = Layout()
        #expect(subject.numberOfEmptyFreeCells == 4)
        #expect(subject.indexOfFirstEmptyFreeCell == 0)
        subject.freeCells[0].cards = [Card(rank: .jack, suit: .hearts)]
        subject.freeCells[2].cards = [Card(rank: .queen, suit: .hearts)]
        #expect(subject.numberOfEmptyFreeCells == 2)
        #expect(subject.indexOfFirstEmptyFreeCell == 1)
    }

    @Test("empty columns works correctly")
    func emptyColumns() {
        var subject = Layout()
        #expect(subject.numberOfEmptyColumns == 8)
        #expect(subject.indexOfFirstEmptyColumn == 0)
        subject.columns[0].cards = [Card(rank: .jack, suit: .hearts)]
        subject.columns[2].cards = [Card(rank: .queen, suit: .hearts)]
        #expect(subject.numberOfEmptyColumns == 6)
        #expect(subject.indexOfFirstEmptyColumn == 1)
    }

    @Test("numberOfCardsRemaining works correctly")
    func numberOfCardsRemaining() {
        var subject = Layout()
        #expect(subject.numberOfCardsRemaining == 0)
        subject.freeCells[0].cards = [Card(rank: .jack, suit: .hearts)]
        subject.freeCells[2].cards = [Card(rank: .queen, suit: .hearts)]
        subject.columns[0].cards = [Card(rank: .jack, suit: .hearts)]
        subject.columns[2].cards = [
            Card(rank: .jack, suit: .hearts),
            Card(rank: .queen, suit: .hearts),
        ]
        #expect(subject.numberOfCardsRemaining == 5)
    }

    @Test("entropy: correctly describes the orderedness of the columns")
    func entropy() {
        do {
            var subject = Layout()
            subject.columns[0].cards = [
                Card(rank: .queen, suit: .hearts),
                Card(rank: .jack, suit: .spades),
                Card(rank: .ten, suit: .hearts),
                Card(rank: .nine, suit: .spades),
            ]
            let result = subject.entropy
            #expect(result == 1)
        }
        do {
            var subject = Layout()
            subject.columns[0].cards = [
                Card(rank: .queen, suit: .hearts),
                Card(rank: .jack, suit: .spades),
                Card(rank: .ten, suit: .hearts),
                Card(rank: .nine, suit: .spades),
            ].reversed()
            let result = subject.entropy
            #expect(result == 0)
        }
    }

    @Test("cardAtLocation: works correctly")
    func cardAtLocation() {
        var subject = Layout()
        subject.freeCells[0].cards = [Card(rank: .jack, suit: .hearts)]
        subject.columns[0].cards = [Card(rank: .ten, suit: .hearts)]
        subject.foundations[0].cards = [Card(rank: .nine, suit: .spades)]
        #expect(subject.card(at: Location(category: .freeCell, index: 0)) == Card(rank: .jack, suit: .hearts))
        #expect(subject.card(at: Location(category: .freeCell, index: 1)) == nil)
        #expect(subject.card(at: Location(category: .column, index: 0)) == Card(rank: .ten, suit: .hearts))
        #expect(subject.card(at: Location(category: .column, index: 1)) == nil)
        #expect(subject.card(at: Location(category: .foundation, index: 0)) == Card(rank: .nine, suit: .spades))
        #expect(subject.card(at: Location(category: .foundation, index: 1)) == nil)
    }

    @Test("cardAtLocation:internalIndex: with index -1 reduces to cardAtLocation")
    func cardAtLocationInternalIndexMinusOne() {
        var subject = Layout()
        subject.freeCells[0].cards = [Card(rank: .jack, suit: .hearts)]
        subject.columns[0].cards = [Card(rank: .ten, suit: .hearts)]
        subject.foundations[0].cards = [Card(rank: .nine, suit: .spades)]
        #expect(subject.card(at: Location(category: .freeCell, index: 0), internalIndex: -1) == Card(rank: .jack, suit: .hearts))
        #expect(subject.card(at: Location(category: .freeCell, index: 1), internalIndex: -1) == nil)
        #expect(subject.card(at: Location(category: .column, index: 0), internalIndex: -1) == Card(rank: .ten, suit: .hearts))
        #expect(subject.card(at: Location(category: .column, index: 1), internalIndex: -1) == nil)
        #expect(subject.card(at: Location(category: .foundation, index: 0), internalIndex: -1) == Card(rank: .nine, suit: .spades))
        #expect(subject.card(at: Location(category: .foundation, index: 1), internalIndex: -1) == nil)
    }

    @Test("cardAtLocation:internalIndex: with index not -1 gets correct card")
    func cardAtLocationInternalIndexPositive() {
        var subject = Layout()
        subject.freeCells[0].cards = [Card(rank: .jack, suit: .hearts)]
        subject.columns[0].cards = [
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .diamonds)
        ]
        subject.foundations[0].cards = [
            Card(rank: .eight, suit: .spades),
            Card(rank: .nine, suit: .spades)
        ]
        #expect(subject.card(at: Location(category: .freeCell, index: 0), internalIndex: 0) == Card(rank: .jack, suit: .hearts))
        #expect(subject.card(at: Location(category: .freeCell, index: 0), internalIndex: 1) == nil)
        #expect(subject.card(at: Location(category: .freeCell, index: 1), internalIndex: 0) == nil)
        #expect(subject.card(at: Location(category: .column, index: 0), internalIndex: 0) == Card(rank: .ten, suit: .hearts))
        #expect(subject.card(at: Location(category: .column, index: 0), internalIndex: 1) == Card(rank: .nine, suit: .clubs))
        #expect(subject.card(at: Location(category: .column, index: 0), internalIndex: 2) == Card(rank: .eight, suit: .diamonds))
        #expect(subject.card(at: Location(category: .column, index: 0), internalIndex: 3) == nil)
        #expect(subject.card(at: Location(category: .column, index: 1), internalIndex: 0) == nil)
        #expect(subject.card(at: Location(category: .foundation, index: 0), internalIndex: 0) == Card(rank: .eight, suit: .spades))
        #expect(subject.card(at: Location(category: .foundation, index: 0), internalIndex: 1) == Card(rank: .nine, suit: .spades))
        #expect(subject.card(at: Location(category: .foundation, index: 1), internalIndex: 0) == nil)
    }

    @Test("surrenderCardfromLocation: works correctly")
    func surrenderCardFromLocation() {
        var subject = Layout()
        subject.freeCells[0].cards = [Card(rank: .ten, suit: .hearts)]
        subject.columns[0].cards = [Card(rank: .nine, suit: .spades)]
        #expect(subject.surrenderCard(from: Location(category: .freeCell, index: 0)) == Card(rank: .ten, suit: .hearts))
        #expect(subject.freeCells[0].card == nil)
        #expect(subject.surrenderCard(from: Location(category: .column, index: 0)) == Card(rank: .nine, suit: .spades))
        #expect(subject.columns[0].cards.isEmpty)
    }

    @Test("allLocationsAndCards gives correct result")
    func allLocationsAndCards() {
        var subject = Layout()
        subject.freeCells[0].cards = [Card(rank: .jack, suit: .hearts)]
        subject.columns[0].cards = [
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .diamonds)
        ]
        subject.foundations[0].cards = [
            Card(rank: .eight, suit: .spades),
            Card(rank: .nine, suit: .spades)
        ]
        let result = Set(subject.allLocationsAndCards())
        #expect(result.count == 6)
        #expect(result.contains(LocationAndCard(location: Location(category: .freeCell, index: 0), internalIndex: 0, card: Card(rank: .jack, suit: .hearts))))
        #expect(result.contains(LocationAndCard(location: Location(category: .column, index: 0), internalIndex: 0, card: Card(rank: .ten, suit: .hearts))))
        #expect(result.contains(LocationAndCard(location: Location(category: .column, index: 0), internalIndex: 1, card: Card(rank: .nine, suit: .clubs))))
        #expect(result.contains(LocationAndCard(location: Location(category: .column, index: 0), internalIndex: 2, card: Card(rank: .eight, suit: .diamonds))))
        #expect(result.contains(LocationAndCard(location: Location(category: .foundation, index: 0), internalIndex: 0, card: Card(rank: .eight, suit: .spades))))
        #expect(result.contains(LocationAndCard(location: Location(category: .foundation, index: 0), internalIndex: 1, card: Card(rank: .nine, suit: .spades))))
    }


    @Test("deal deals correctly")
    func deal() {
        var subject = Layout()
        subject.freeCells[0].cards = [Card(rank: .jack, suit: .hearts)]
        subject.freeCells[2].cards = [Card(rank: .queen, suit: .hearts)]
        subject.columns[0].cards = [Card(rank: .jack, suit: .hearts)]
        subject.columns[2].cards = [
            Card(rank: .jack, suit: .hearts),
            Card(rank: .queen, suit: .hearts),
        ]
        subject.microsoftDealNumber = 1
        subject.deal(Deck())
        let expected = """
            FOUNDATIONS: XX XX XX XX
            FREE CELLS:  XX XX XX XX
            
            AH AD AS AC 2H 2D 2S 2C
            3H 3D 3S 3C 4H 4D 4S 4C
            5H 5D 5S 5C 6H 6D 6S 6C
            7H 7D 7S 7C 8H 8D 8S 8C
            9H 9D 9S 9C TH TD TS TC
            JH JD JS JC QH QD QS QC
            KH KD KS KC
            \n
            """
        #expect(subject.description == expected)
        #expect(subject.microsoftDealNumber == nil)
    }

    @Test("deal microsoft number deals correctly and sets microsoft number")
    func dealMicrosoft() {
        var subject = Layout()
        subject.freeCells[0].cards = [Card(rank: .jack, suit: .hearts)]
        subject.freeCells[2].cards = [Card(rank: .queen, suit: .hearts)]
        subject.columns[0].cards = [Card(rank: .jack, suit: .hearts)]
        subject.columns[2].cards = [
            Card(rank: .jack, suit: .hearts),
            Card(rank: .queen, suit: .hearts),
        ]
        subject.microsoftDealNumber = 2
        subject.deal(microsoftDealNumber: 1)
        /*
         deck is:
         JD 2D 9H JC 5D 7H 7C 5H
         KD KC 9S 5S AD QC KH 3H
         2S KS 9D QD JS AS AH 3C
         4C 5C TS QH 4H AC 4D 7S
         3S TD 4S TH 8H 2C JH 7D
         6D 8S 8D QS 6C 3D 8C TC
         6S 9C 2H 6H
         */
        let expected = """
            FOUNDATIONS: XX XX XX XX
            FREE CELLS:  XX XX XX XX
            
            JD 2D 9H JC 5D 7H 7C 5H
            KD KC 9S 5S AD QC KH 3H
            2S KS 9D QD JS AS AH 3C
            4C 5C TS QH 4H AC 4D 7S
            3S TD 4S TH 8H 2C JH 7D
            6D 8S 8D QS 6C 3D 8C TC
            6S 9C 2H 6H
            \n
            """
        #expect(subject.description == expected)
        #expect(subject.microsoftDealNumber == 1)
    }

    @Test("mightNeed: gives the right answer")
    func mightNeed() {
        var subject = Layout()
        #expect(subject.mightNeed(card: Card(rank: .ace, suit: .hearts)) == false)
        #expect(subject.mightNeed(card: Card(rank: .two, suit: .hearts)) == false)
        // if AH and 2D are up, then 3S is not needed
        subject.foundations[subject.indexOfFoundation(for: .hearts)].cards = [Card(rank: .ace, suit: .hearts)]
        subject.foundations[subject.indexOfFoundation(for: .diamonds)].cards = [Card(rank: .two, suit: .hearts)]
        #expect(subject.mightNeed(card: Card(rank: .three, suit: .spades)) == false)
        // if both black sixes are up, the seven of diamonds is not needed
        let card = Card(rank: .seven, suit: .diamonds)
        subject.foundations[subject.indexOfFoundation(for: .clubs)].cards = [Card(rank: .six, suit: .clubs)]
        subject.foundations[subject.indexOfFoundation(for: .spades)].cards = [Card(rank: .six, suit: .spades)]
        #expect(subject.mightNeed(card: card) == false)
        // edge cases
        subject.foundations[subject.indexOfFoundation(for: .clubs)].cards = []
        #expect(subject.mightNeed(card: card) == true)
        subject.foundations[subject.indexOfFoundation(for: .clubs)].cards = [Card(rank: .five, suit: .clubs)]
        #expect(subject.mightNeed(card: card) == true)
        subject.foundations[subject.indexOfFoundation(for: .clubs)].cards = [Card(rank: .seven, suit: .clubs)]
        #expect(subject.mightNeed(card: card) == false)
        // if both black fives and the heart four are up, the seven of diamonds is not needed
        subject.foundations[subject.indexOfFoundation(for: .clubs)].cards = [Card(rank: .five, suit: .clubs)]
        subject.foundations[subject.indexOfFoundation(for: .spades)].cards = [Card(rank: .five, suit: .spades)]
        subject.foundations[subject.indexOfFoundation(for: .hearts)].cards = [Card(rank: .four, suit: .hearts)]
        #expect(subject.mightNeed(card: card) == false)
        // edge cases
        // vary the rank of the target card
        #expect(subject.mightNeed(card: Card(rank: .six, suit: .diamonds)) == false)
        #expect(subject.mightNeed(card: Card(rank: .eight, suit: .diamonds)) == true)
        // vary the rank of the foundation tops
        // the partner
        subject.foundations[subject.indexOfFoundation(for: .hearts)].cards = [Card(rank: .three, suit: .hearts)]
        #expect(subject.mightNeed(card: card) == true)
        subject.foundations[subject.indexOfFoundation(for: .hearts)].cards = [Card(rank: .five, suit: .hearts)]
        #expect(subject.mightNeed(card: card) == false)
        subject.foundations[subject.indexOfFoundation(for: .hearts)].cards = [Card(rank: .four, suit: .hearts)]
        // one of the opposites
        subject.foundations[subject.indexOfFoundation(for: .clubs)].cards = [Card(rank: .four, suit: .clubs)]
        #expect(subject.mightNeed(card: card) == true)
        subject.foundations[subject.indexOfFoundation(for: .clubs)].cards = [Card(rank: .six, suit: .clubs)]
        #expect(subject.mightNeed(card: card) == false)
        subject.foundations[subject.indexOfFoundation(for: .clubs)].cards = [Card(rank: .five, suit: .clubs)]
        // the other of the opposites
        subject.foundations[subject.indexOfFoundation(for: .spades)].cards = [Card(rank: .four, suit: .spades)]
        #expect(subject.mightNeed(card: card) == true)
        subject.foundations[subject.indexOfFoundation(for: .spades)].cards = [Card(rank: .six, suit: .spades)]
        #expect(subject.mightNeed(card: card) == false)
        subject.foundations[subject.indexOfFoundation(for: .spades)].cards = [Card(rank: .five, suit: .spades)]
        // and what if any of the others is empty?
        subject.foundations[subject.indexOfFoundation(for: .hearts)].cards = []
        #expect(subject.mightNeed(card: card) == true)
        subject.foundations[subject.indexOfFoundation(for: .hearts)].cards = [Card(rank: .four, suit: .hearts)]
        subject.foundations[subject.indexOfFoundation(for: .clubs)].cards = []
        #expect(subject.mightNeed(card: card) == true)
        subject.foundations[subject.indexOfFoundation(for: .clubs)].cards = [Card(rank: .five, suit: .clubs)]
        subject.foundations[subject.indexOfFoundation(for: .spades)].cards = []
        #expect(subject.mightNeed(card: card) == true)
        subject.foundations[subject.indexOfFoundation(for: .spades)].cards = [Card(rank: .five, suit: .spades)]
    }

    @Test("howManyCardsCanMoveLegally: is right when sequence moves are turned off")
    func howManyCardsCanMoveLegallyNoSequenceMoves() {
        var subject = Layout()
        subject.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
        subject.columns[1].cards = [
            Card(rank: .queen, suit: .diamonds),
            Card(rank: .jack, suit: .clubs)
        ]
        var result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: false,
            supermoves: true
        )
        #expect(result == 1)
        subject.columns[0].cards = [Card(rank: .king, suit: .spades)]
        subject.columns[1].cards = [
            Card(rank: .queen, suit: .diamonds),
            Card(rank: .jack, suit: .clubs)
        ]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: false,
            supermoves: true
        )
        #expect(result == 0) // without sequence moves, this is a no-go
    }

    @Test("howManyCardsCanMoveLegally: is right when the source contains just one card")
    func howManyCardsCanMoveLegallyOnlyOneCard() {
        var subject = Layout()
        subject.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
        subject.columns[1].cards = [Card(rank: .jack, suit: .clubs)]
        var result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 1)
        subject.columns[0].cards = [Card(rank: .king, suit: .spades)]
        subject.columns[1].cards = [Card(rank: .jack, suit: .clubs)]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 0)
    }

    @Test("howManyCardsCanMoveLegally: is right when sequence moves are on but no supermoves")
    func howManyCardsCanMoveLegallyNoSupermoves() {
        var subject = Layout()
        subject.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
        subject.columns[1].cards = [
            Card(rank: .queen, suit: .diamonds),
            Card(rank: .jack, suit: .clubs)
        ]
        var result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 1)
        subject.columns[1].cards = [
            Card(rank: .queen, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts)
        ]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 2)
        // ... and so on ...
        subject.columns[1].cards = [
            Card(rank: .queen, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .clubs),
            Card(rank: .six, suit: .hearts),
            Card(rank: .five, suit: .clubs),
            Card(rank: .four, suit: .hearts),
            Card(rank: .three, suit: .clubs),
            Card(rank: .two, suit: .hearts)
        ]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 10)
        subject.columns[1].cards = [
            Card(rank: .queen, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .clubs),
            Card(rank: .six, suit: .hearts),
            Card(rank: .five, suit: .clubs),
            Card(rank: .four, suit: .hearts),
            Card(rank: .three, suit: .clubs),
            Card(rank: .two, suit: .hearts),
            Card(rank: .two, suit: .clubs) // haha
        ]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 0)
        // okay, now I'm going to start removing free space
        subject.columns[1].cards = [
            Card(rank: .queen, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .clubs),
            Card(rank: .six, suit: .hearts),
            Card(rank: .five, suit: .clubs),
            Card(rank: .four, suit: .hearts),
            Card(rank: .three, suit: .clubs),
            Card(rank: .two, suit: .hearts),
        ]
        subject.freeCells[0].cards = [Card(rank: .two, suit: .clubs)]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 10)
        subject.freeCells[1].cards = [Card(rank: .two, suit: .clubs)]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 0) // because without a supermove we cannot free up the jack
        // and the same if we occupy a column instead of a freecell
        subject.freeCells[1].cards = []
        subject.columns[7].cards = [Card(rank: .two, suit: .clubs)]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 0) // because without a supermove we cannot free up the jack
    }

    @Test("howManyCardsCanMoveLegally: is right when sequence moves are on but no supermoves and moving to an empty column")
    func howManyCardsCanMoveLegallyNoSupermovesDesinationEmpty() {
        var subject = Layout()
        subject.columns[1].cards = [
            Card(rank: .king, suit: .diamonds),
            Card(rank: .jack, suit: .clubs)
        ]
        var result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 1)
        subject.columns[1].cards = [
            Card(rank: .king, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts)
        ]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 2)
        // ... and so on ...
        subject.columns[1].cards = [
            Card(rank: .king, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .clubs),
            Card(rank: .six, suit: .hearts),
            Card(rank: .five, suit: .clubs),
            Card(rank: .four, suit: .hearts),
            Card(rank: .three, suit: .clubs),
            Card(rank: .two, suit: .hearts),
        ]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 10)
        subject.columns[1].cards = [
            Card(rank: .king, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .clubs),
            Card(rank: .six, suit: .hearts),
            Card(rank: .five, suit: .clubs),
            Card(rank: .four, suit: .hearts),
            Card(rank: .three, suit: .clubs),
            Card(rank: .two, suit: .hearts),
            Card(rank: .two, suit: .clubs) // haha
        ]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 1)
        // okay, now I'm going to start removing free space
        subject.columns[1].cards = [
            Card(rank: .king, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .clubs),
            Card(rank: .six, suit: .hearts),
            Card(rank: .five, suit: .clubs),
            Card(rank: .four, suit: .hearts),
            Card(rank: .three, suit: .clubs),
            Card(rank: .two, suit: .hearts),
        ]
        subject.freeCells[0].cards = [Card(rank: .two, suit: .clubs)]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 10)
        subject.freeCells[1].cards = [Card(rank: .two, suit: .clubs)]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 9)
        // and the same if we occupy a column instead of a freecell
        subject.freeCells[1].cards = []
        subject.columns[7].cards = [Card(rank: .two, suit: .clubs)]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 9)
        subject.columns[6].cards = [Card(rank: .two, suit: .clubs)]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 8)
        subject.columns[5].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[4].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[3].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[2].cards = [Card(rank: .two, suit: .clubs)]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 4)
        subject.freeCells[1].cards = [Card(rank: .two, suit: .clubs)]
        subject.freeCells[2].cards = [Card(rank: .two, suit: .clubs)]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 2)
        subject.freeCells[3].cards = [Card(rank: .two, suit: .clubs)]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: false
        )
        #expect(result == 1)
    }

    @Test("howManyCardsCanMoveLegally: is right with supermoves")
    func howManyCardsCanMoveLegallySupermoves() {
        // if there are no empty columns, the situation is no different from no supermoves
        var subject = Layout()
        subject.freeCells[0].cards = [Card(rank: .two, suit: .clubs)]
        subject.freeCells[1].cards = [Card(rank: .two, suit: .clubs)]
        subject.freeCells[2].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[2].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[3].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[4].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[5].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[6].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[7].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
        subject.columns[1].cards = [
            Card(rank: .queen, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs)
        ]
        var result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 0) // cannot free up the jack
        subject.freeCells[2].cards = []
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 3) // because now there are enough freecells
        // okay, but now I'm going to free up a column
        // so, we have one freecell and one column
        subject.columns[7].cards = []
        subject.freeCells[2].cards = [Card(rank: .two, suit: .clubs)]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 3) // obviously
        // but now watch _this_ little move; I'm going to add to the source
        subject.columns[1].cards = [
            Card(rank: .queen, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .hearts)
        ]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 4) // supermove! two cards can go in the column and one in the freecell
        subject.columns[1].cards = [
            Card(rank: .queen, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .clubs)
        ]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 0) // we hit a wall - but now let's free up another column...
        subject.columns[6].cards = []
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 5) // supermove!
        // ... and so on ...
        subject.columns[1].cards = [
            Card(rank: .queen, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .clubs),
            Card(rank: .six, suit: .hearts),
            Card(rank: .five, suit: .clubs),
            Card(rank: .four, suit: .hearts)
        ]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 8) // supermove! 8 is (2^2 columns) * (2 = 1 free cell plus 1)
        subject.columns[1].cards = [
            Card(rank: .queen, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .clubs),
            Card(rank: .six, suit: .hearts),
            Card(rank: .five, suit: .clubs),
            Card(rank: .four, suit: .hearts),
            Card(rank: .three, suit: .clubs)
        ]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 0) // stuck!
    }

    @Test("howManyCardsCanMoveLegally: is right when sequence moves are on with supermoves and moving to an empty column")
    func howManyCardsCanMoveLegallySupermovesDesinationEmpty() {
        var subject = Layout()
        subject.columns[1].cards = [
            Card(rank: .king, suit: .diamonds),
            Card(rank: .jack, suit: .clubs)
        ]
        var result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 1)
        subject.columns[1].cards = [
            Card(rank: .king, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts)
        ]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 2)
        // ... and so on ...
        subject.columns[1].cards = [
            Card(rank: .king, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .clubs),
            Card(rank: .six, suit: .hearts),
            Card(rank: .five, suit: .clubs),
            Card(rank: .four, suit: .hearts),
            Card(rank: .three, suit: .clubs),
            Card(rank: .two, suit: .hearts),
        ]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 10)
        subject.columns[1].cards = [
            Card(rank: .king, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .clubs),
            Card(rank: .six, suit: .hearts),
            Card(rank: .five, suit: .clubs),
            Card(rank: .four, suit: .hearts),
            Card(rank: .three, suit: .clubs),
            Card(rank: .two, suit: .hearts),
            Card(rank: .two, suit: .clubs) // haha
        ]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 1)
        // okay, now I'm going to start removing free space
        subject.columns[1].cards = [
            Card(rank: .king, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .clubs),
            Card(rank: .six, suit: .hearts),
            Card(rank: .five, suit: .clubs),
            Card(rank: .four, suit: .hearts),
            Card(rank: .three, suit: .clubs),
            Card(rank: .two, suit: .hearts),
        ]
        subject.freeCells[0].cards = [Card(rank: .two, suit: .clubs)]
        subject.freeCells[1].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[2].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[3].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[4].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[5].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[6].cards = [Card(rank: .two, suit: .clubs)]
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 6)
        // and that is correct: there are two free cells and one empty column, so move three
        // cards into the empty column (using the two free cells), then two cards into the
        // two free cells, then the sixth card into the destination, then unravel
        subject.freeCells[2].cards = [Card(rank: .two, suit: .clubs)]
        subject.columns[6].cards = []
        result = subject.howManyCardsCanMoveLegally(
            from: 1,
            to: 0,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 8)
        /// and that is correct: there is one free cell and two empty columns, same formula as
        /// previous test, (2^2 columns) * (2 = 1 free cell plus 1)
    }

    @Test("howManyCardsCanMoveLegally: returns zero when all a column's cards would move to an empty column")
    func howManyCardsCanMoveLegallyAllToEmpty() {
        var subject = Layout()
        subject.columns[0].cards = [
            Card(rank: .king, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
        ]
        subject.columns[1].cards = [Card(rank: .queen, suit: .hearts)]
        subject.columns[2].cards = []
        var result = subject.howManyCardsCanMoveLegally(
            from: 0,
            to: 1,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 3)
        result = subject.howManyCardsCanMoveLegally(
            from: 0,
            to: 2,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 3)
        subject.columns[0].cards = [
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
        ]
        subject.columns[1].cards = [Card(rank: .queen, suit: .hearts)]
        subject.columns[2].cards = []
        result = subject.howManyCardsCanMoveLegally(
            from: 0,
            to: 1,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 3)
        result = subject.howManyCardsCanMoveLegally(
            from: 0,
            to: 2,
            sequenceMoves: true,
            supermoves: true
        )
        #expect(result == 0) // *
    }

    @Test("playToFoundationIfSafeAndPossible: behaves as expected")
    func playToFoundation() {
        var subject = Layout()
        subject.columns[0].cards = [
            Card(rank: .three, suit: .spades),
            Card(rank: .two, suit: .spades),
            Card(rank: .ace, suit: .spades),
        ]
        var result = subject.playToFoundationIfSafeAndPossible(location: Location(category: .column, index: 0))
        #expect(result == true)
        #expect(subject.foundations[0].card == Card(rank: .ace, suit: .spades))
        #expect(subject.columns[0].cards == [
            Card(rank: .three, suit: .spades),
            Card(rank: .two, suit: .spades),
        ])
        result = subject.playToFoundationIfSafeAndPossible(location: Location(category: .column, index: 0))
        #expect(result == true)
        #expect(subject.foundations[0].card == Card(rank: .two, suit: .spades))
        #expect(subject.columns[0].cards == [
            Card(rank: .three, suit: .spades),
        ])
        result = subject.playToFoundationIfSafeAndPossible(location: Location(category: .column, index: 0))
        // nothing happens, might need the three
        #expect(result == false)
        #expect(subject.foundations[0].card == Card(rank: .two, suit: .spades))
        #expect(subject.columns[0].cards == [
            Card(rank: .three, suit: .spades),
        ])
        // okay, I'll prove you don't need the three after all
        subject.foundations[1].cards = [Card(rank: .two, suit: .hearts)]
        subject.foundations[3].cards = [Card(rank: .two, suit: .diamonds)]
        result = subject.playToFoundationIfSafeAndPossible(location: Location(category: .column, index: 0))
        #expect(result == true)
        #expect(subject.foundations[0].card == Card(rank: .three, suit: .spades))
        #expect(subject.columns[0].cards == [])
        // and at this point we are merely repeating the tests for `mightNeed`, so enough
    }

    @Test("autoplay: behaves as expected")
    func autoplay() {
        do {
            var subject = Layout()
            subject.columns[0].cards = [
                Card(rank: .three, suit: .spades),
                Card(rank: .two, suit: .spades),
                Card(rank: .ace, suit: .spades),
            ]
            subject.autoplay()
            #expect(subject.foundations[0].cards == [
                Card(rank: .ace, suit: .spades),
                Card(rank: .two, suit: .spades),
            ])
            #expect(subject.columns[0].cards == [
                Card(rank: .three, suit: .spades),
            ])
        }
        do {
            var subject = Layout()
            subject.columns[0].cards = [
                Card(rank: .three, suit: .spades),
                Card(rank: .two, suit: .spades),
                Card(rank: .ace, suit: .spades),
            ]
            subject.columns[1].cards = [
                Card(rank: .two, suit: .hearts),
                Card(rank: .ace, suit: .hearts),
            ]
            subject.columns[2].cards = [
                Card(rank: .two, suit: .diamonds),
                Card(rank: .ace, suit: .diamonds),
            ]
            subject.autoplay()
            #expect(subject.foundations[0].cards == [
                Card(rank: .ace, suit: .spades),
                Card(rank: .two, suit: .spades),
                Card(rank: .three, suit: .spades),
            ])
            #expect(subject.foundations[1].cards == [
                Card(rank: .ace, suit: .hearts),
                Card(rank: .two, suit: .hearts),
            ])
            #expect(subject.foundations[3].cards == [
                Card(rank: .ace, suit: .diamonds),
                Card(rank: .two, suit: .diamonds),
            ])
            #expect(subject.columns[0].cards == [])
            #expect(subject.columns[1].cards == [])
            #expect(subject.columns[2].cards == [])
        }
        // and again, any further testing would just repeat `mightNeed`
    }

    @Test("splat: behaves as expected")
    func splat() {
        var subject = Layout()
        subject.columns[1].cards = [Card(rank: .ace, suit: .spades)]
        subject.columns[2].cards = [Card(rank: .ace, suit: .spades)]
        subject.columns[4].cards = [Card(rank: .ace, suit: .spades)]
        subject.columns[6].cards = [Card(rank: .ace, suit: .spades)]
        subject.columns[5].cards = [
            Card(rank: .four, suit: .spades),
            Card(rank: .seven, suit: .hearts),
            Card(rank: .ten, suit: .diamonds),
            Card(rank: .nine, suit: .diamonds),
            Card(rank: .eight, suit: .diamonds),
            Card(rank: .seven, suit: .diamonds),
            Card(rank: .six, suit: .diamonds),
        ]
        subject.splat(index: 5)
        #expect(subject.description == """
        FOUNDATIONS: XX XX XX XX
        FREE CELLS:  6D 7D 8D 9D
        
        TD AS AS 7H AS 4S AS
        
        
        """)
    }

    @Test("tableauDescription looks right")
    func tableauDescription() {
        do {
            var subject = Layout()
            subject.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.columns[1].cards = [
                Card(rank: .queen, suit: .diamonds),
                Card(rank: .jack, suit: .clubs),
            ]
            subject.columns[7].cards = [
                Card(rank: .ten, suit: .hearts),
            ]
            let expected = """
            QH QD                TH
               JC\n
            """
            let result = subject.tableauDescription
            #expect(result == expected)
        }
        do {
            var subject = Layout()
            subject.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
            subject.columns[1].cards = [
                Card(rank: .queen, suit: .diamonds),
                Card(rank: .jack, suit: .clubs),
                Card(rank: .ten, suit: .hearts),
                Card(rank: .nine, suit: .clubs),
                Card(rank: .eight, suit: .hearts),
                Card(rank: .seven, suit: .clubs),
                Card(rank: .six, suit: .hearts),
                Card(rank: .five, suit: .clubs),
                Card(rank: .four, suit: .hearts),
                Card(rank: .three, suit: .clubs),
                Card(rank: .two, suit: .hearts)
            ]
            let expected = """
            QH QD
               JC
               TH
               9C
               8H
               7C
               6H
               5C
               4H
               3C
               2H\n
            """
            let result = subject.tableauDescription
            #expect(result == expected)
        }
        do {
            var subject = Layout()
            subject.deal(Deck())
            let expected = """
            AH AD AS AC 2H 2D 2S 2C
            3H 3D 3S 3C 4H 4D 4S 4C
            5H 5D 5S 5C 6H 6D 6S 6C
            7H 7D 7S 7C 8H 8D 8S 8C
            9H 9D 9S 9C TH TD TS TC
            JH JD JS JC QH QD QS QC
            KH KD KS KC\n
            """
            let result = subject.tableauDescription
            #expect(result == expected)
        }
    }

    @Test("old style tableau description translates into new style tableau description")
    func oldToNewTableauDescription() {
        // we need to know this because we are going to do it to the stats dictionary
        func toOldTableauDescription(_ layout: Layout) -> String {
            var output = ""
            var maxempty = 0
            var row = 0
            loop: while true {
                for column in layout.columns {
                    if column.cards.count > row {
                        output.write(column.cards[row].description)
                        maxempty = 0
                    } else {
                        output.write("  ")
                        maxempty += 1
                    }
                    output.write(" ")
                    if maxempty > layout.columns.count {
                        break loop
                    }
                }
                row += 1
                output.write("\n")
            }
            return output // without trimming
        }
        var layout = Layout()
        var deck = Deck()
        deck.shuffle()
        layout.deal(deck)
        let oldDesc = toOldTableauDescription(layout)
        let newDesc = layout.tableauDescription
        #expect(oldDesc.trimmingWhitespacesFromLineEnds == newDesc)
    }

    @Test("Shlomi tableau description is correct")
    func shlomiTableau() {
        var subject = Layout()
        subject.columns[0].cards = [Card(rank: .queen, suit: .hearts)]
        subject.columns[1].cards = [
            Card(rank: .queen, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .clubs),
            Card(rank: .six, suit: .hearts),
            Card(rank: .five, suit: .clubs),
            Card(rank: .four, suit: .hearts),
            Card(rank: .three, suit: .clubs),
            Card(rank: .two, suit: .hearts)
        ]
        var expected = """
            QH
            QD JC TH 9C 8H 7C 6H 5C 4H 3C 2H
            
            
            
            
            
            \n
            """
        var result = subject.shlomiTableauDescription
        #expect(result == expected)
        subject.deal(Deck())
        expected = """
            AH 3H 5H 7H 9H JH KH
            AD 3D 5D 7D 9D JD KD
            AS 3S 5S 7S 9S JS KS
            AC 3C 5C 7C 9C JC KC
            2H 4H 6H 8H TH QH
            2D 4D 6D 8D TD QD
            2S 4S 6S 8S TS QS
            2C 4C 6C 8C TC QC\n
            """
        result = subject.shlomiTableauDescription
        #expect(result == expected)
    }

    @Test("init from shlomi description works")
    func initShlomiDescription() {
        let description = """
            QH
            QD JC TH 9C 8H 7C 6H 5C 4H 3C 2H
            
            
            
            
            
            \n
            """
        var result = Layout(shlomiTableauDescription: description)
        #expect(result == nil) // invalid, not enough cards
        let description2 = """
            AH 3H 5H 7H 9H JH KH
            AD 3D 5D 7D 9D JD KD
            AS 3S 5S 7S 9S JS KS
            AC 3C 5C 7C 9C JC KC
            2H 4H 6H 8H TH QH
            2D 4D 6D 8D TD QD
            2S 4S 6S 8S TS QS
            2C 4C 6C 8C TC QC\n
            """
        result = Layout(shlomiTableauDescription: description2)
        #expect(result != nil)
        let expected = """
            AH AD AS AC 2H 2D 2S 2C
            3H 3D 3S 3C 4H 4D 4S 4C
            5H 5D 5S 5C 6H 6D 6S 6C
            7H 7D 7S 7C 8H 8D 8S 8C
            9H 9D 9S 9C TH TD TS TC
            JH JD JS JC QH QD QS QC
            KH KD KS KC\n
            """
        #expect(result!.tableauDescription == expected)
    }

    @Test("description looks right")
    func description() {
        var subject = Layout()
        subject.columns[1].cards = [
            Card(rank: .king, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .hearts)
        ]
        subject.columns[7].cards = [Card(rank: .two, suit: .clubs)]
        subject.freeCells[0].cards = [Card(rank: .two, suit: .clubs)]
        subject.freeCells[2].cards = [Card(rank: .two, suit: .clubs)]
        subject.foundations[subject.indexOfFoundation(for: .diamonds)].cards = [Card(rank: .ace, suit: .diamonds)]
        let result = subject.description
        let expected = """
            FOUNDATIONS: XX XX XX AD
            FREE CELLS:  2C XX 2C XX
            
               KD                2C
               JC
               TH
            \n
            """
        #expect(result == expected)
    }
}
