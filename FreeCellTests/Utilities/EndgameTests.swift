@testable import TTFreeCell
import Testing
import Foundation

private struct EndgameTests {
    let subject = Endgame()

    @Test("evaluate: splats column, returns that layout and autoplay layout if win")
    func splatOne() {
        var layout = Layout()
        layout.columns[1].cards = [Card(rank: .eight, suit: .hearts)]
        layout.columns[2].cards = [Card(rank: .nine, suit: .hearts)]
        layout.columns[4].cards = [Card(rank: .ten, suit: .hearts)]
        layout.columns[5].cards = [
            Card(rank: .nine, suit: .spades),
            Card(rank: .ten, suit: .spades),
            Card(rank: .jack, suit: .spades),
            Card(rank: .queen, suit: .spades),
            Card(rank: .king, suit: .spades),
        ]
        layout.columns[6].cards = [
            Card(rank: .king, suit: .hearts),
            Card(rank: .queen, suit: .hearts),
            Card(rank: .jack, suit: .hearts),
        ]
        layout.foundations[0].cards = [Card(rank: .eight, suit: .spades)]
        layout.foundations[1].cards = [Card(rank: .seven, suit: .hearts)]
        layout.foundations[2].cards = [Card(rank: .king, suit: .clubs)]
        layout.foundations[3].cards = [Card(rank: .king, suit: .diamonds)]
        let result = subject.evaluate(layout)
        #expect(result.count == 2)
        #expect(result[0].description == """
        FOUNDATIONS: 8S 7H KC KD
        FREE CELLS:  KS QS JS TS
        
           8H 9H    TH 9S KH
                          QH
                          JH
        
        
        """) // ... we splatted column 5
        #expect(result[1].description == """
        FOUNDATIONS: KS KH KC KD
        FREE CELLS:  XX XX XX XX
        
        
        
        
        """) // ... then we did a round of autoplay and won
    }

    @Test("evaluate: does not splat perfectly ordered column")
    func splatOneNotOrdered() {
        var layout = Layout()
        layout.columns[5].cards = [
            Card(rank: .king, suit: .spades),
            Card(rank: .queen, suit: .hearts),
            Card(rank: .jack, suit: .spades),
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .spades),
        ]
        layout.columns[6].cards = [
            Card(rank: .ten, suit: .spades),
            Card(rank: .queen, suit: .spades),
            Card(rank: .jack, suit: .hearts),
        ]
        layout.foundations[0].cards = [Card(rank: .eight, suit: .spades)]
        layout.foundations[1].cards = [Card(rank: .nine, suit: .hearts)]
        layout.foundations[2].cards = [Card(rank: .king, suit: .clubs)]
        layout.foundations[3].cards = [Card(rank: .king, suit: .diamonds)]
        let result = subject.evaluate(layout)
        #expect(result.count == 2)
        #expect(result[0].description == """
        FOUNDATIONS: 8S 9H KC KD
        FREE CELLS:  JH QS XX XX
        
                       KS TS
                       QH
                       JS
                       TH
                       9S
        
        
        """) // we splatted column 6 — _not_ column 5
        #expect(result[1].description == """
        FOUNDATIONS: KS QH KC KD
        FREE CELLS:  XX XX XX XX
        
        
        
        
        """) // then we did a round of autoplay and won
    }

    @Test("evaluate: does splat unordered, can do a second round")
    func splatOneUnordered() {
        var layout = Layout()
        layout.columns[5].cards = [
            Card(rank: .nine, suit: .spades), // *
            Card(rank: .king, suit: .spades),
            Card(rank: .queen, suit: .hearts),
            Card(rank: .jack, suit: .spades),
            Card(rank: .ten, suit: .hearts),
        ]
        layout.columns[6].cards = [
            Card(rank: .ten, suit: .spades),
            Card(rank: .queen, suit: .spades),
            Card(rank: .jack, suit: .hearts),
        ]
        layout.foundations[0].cards = [Card(rank: .eight, suit: .spades)]
        layout.foundations[1].cards = [Card(rank: .nine, suit: .hearts)]
        layout.foundations[2].cards = [Card(rank: .king, suit: .clubs)]
        layout.foundations[3].cards = [Card(rank: .king, suit: .diamonds)]
        let result = subject.evaluate(layout)
        #expect(result.count == 4)
        #expect(result[0].description == """
        FOUNDATIONS: 8S 9H KC KD
        FREE CELLS:  TH JS QH KS
        
                       9S TS
                          QS
                          JH
        
        
        """) // we splatted column 5
        #expect(result[1].description == """
        FOUNDATIONS: 9S JH KC KD
        FREE CELLS:  XX JS QH KS
        
                          TS
                          QS
        
        
        """) // then we did a round of autoplay
        #expect(result[2].description == """
        FOUNDATIONS: 9S JH KC KD
        FREE CELLS:  QS JS QH KS
        
                          TS
        
        
        """) // then we did a _second_ splat, splatting column 6
        #expect(result[3].description == """
        FOUNDATIONS: KS QH KC KD
        FREE CELLS:  XX XX XX XX
        
        
        
        
        """) // and when we did another round of autoplay, we won
    }

    @Test("endgame returns empty if we don't win")
    func noWin() {
        var layout = Layout()
        layout.columns[1].cards = [Card(rank: .eight, suit: .hearts)]
        layout.columns[2].cards = [Card(rank: .nine, suit: .hearts)]
        layout.columns[4].cards = [Card(rank: .ten, suit: .hearts)]
        layout.columns[5].cards = [
            Card(rank: .nine, suit: .spades),
            Card(rank: .ten, suit: .spades),
            Card(rank: .jack, suit: .spades),
            Card(rank: .queen, suit: .spades),
            Card(rank: .king, suit: .spades),
        ]
        layout.columns[6].cards = [
            Card(rank: .king, suit: .hearts),
            Card(rank: .queen, suit: .hearts),
            Card(rank: .jack, suit: .hearts),
        ]
        layout.foundations[0].cards = [Card(rank: .eight, suit: .spades)]
        layout.foundations[1].cards = [Card(rank: .six, suit: .hearts)] // no seven so cannot win
        layout.foundations[2].cards = [Card(rank: .king, suit: .clubs)]
        layout.foundations[3].cards = [Card(rank: .king, suit: .diamonds)]
        let result = subject.evaluate(layout)
        #expect(result.isEmpty)
    }
}
