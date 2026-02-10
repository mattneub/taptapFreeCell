@testable import TTFreeCell
import Testing
import Foundation

private struct EndgameHelperTests {
    let subject = EndgameHelper()

    @Test("splat: behaves as expected")
    func splat() {
        var layout = Layout()
        layout.columns[1].cards = [Card(rank: .two, suit: .spades)]
        layout.columns[2].cards = [Card(rank: .two, suit: .spades)]
        layout.columns[4].cards = [Card(rank: .two, suit: .spades)]
        layout.columns[6].cards = [Card(rank: .two, suit: .spades)]
        layout.columns[5].cards = [
            Card(rank: .four, suit: .spades), // the four will not move, it is last
            Card(rank: .seven, suit: .hearts),
            Card(rank: .nine, suit: .diamonds),
            Card(rank: .ace, suit: .spades), // the ace will splat to the foundations
            Card(rank: .eight, suit: .diamonds),
            Card(rank: .seven, suit: .diamonds),
            Card(rank: .six, suit: .diamonds),
        ]
        subject.splat(layout: &layout, index: 5)
        #expect(layout.description == """
        FOUNDATIONS: AS XX XX XX
        FREE CELLS:  6D 7D 8D 9D
        
        7H 2S 2S    2S 4S 2S
        
        
        """)
    }

    @Test("shift: behaves as expected")
    func shift() {
        var layout = Layout()
        layout.columns[1].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[2].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[4].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[6].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[5].cards = [
            Card(rank: .four, suit: .spades),
            Card(rank: .seven, suit: .hearts),
            Card(rank: .ten, suit: .diamonds),
            Card(rank: .nine, suit: .spades),
            Card(rank: .eight, suit: .diamonds),
            Card(rank: .seven, suit: .spades),
            Card(rank: .six, suit: .diamonds),
            Card(rank: .five, suit: .spades)
        ]
        subject.shift(layout: &layout, index: 5)
        #expect(layout.description == """
        FOUNDATIONS: XX XX XX XX
        FREE CELLS:  XX XX XX XX
        
        TD AS AS    AS 4S AS
        9S             7H
        8D
        7S
        6D
        5S
        
        
        """)
    }

    @Test("shift: does nothing if there are no empty columns")
    func shiftNoEmptyColumns() {
        var layout = Layout()
        layout.columns[0].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[1].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[2].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[3].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[4].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[6].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[7].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[5].cards = [
            Card(rank: .four, suit: .spades),
            Card(rank: .seven, suit: .hearts),
            Card(rank: .ten, suit: .diamonds),
            Card(rank: .nine, suit: .spades),
            Card(rank: .eight, suit: .diamonds),
            Card(rank: .seven, suit: .spades),
            Card(rank: .six, suit: .diamonds),
            Card(rank: .five, suit: .spades)
        ]
        let originalLayout = layout
        subject.shift(layout: &layout, index: 5)
        #expect(layout == originalLayout)
    }

    @Test("shift: does nothing if not all of the sequential cards can be moved")
    func shiftNotAll() {
        var layout = Layout()
        layout.columns[0].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[1].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[2].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[3].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[4].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[6].cards = [Card(rank: .ace, suit: .spades)]
        layout.columns[5].cards = [
            Card(rank: .four, suit: .spades),
            Card(rank: .seven, suit: .hearts),
            Card(rank: .ten, suit: .diamonds),
            Card(rank: .nine, suit: .spades),
            Card(rank: .eight, suit: .diamonds),
            Card(rank: .seven, suit: .spades),
            Card(rank: .six, suit: .diamonds),
            Card(rank: .five, suit: .spades)
        ]
        let originalLayout = layout
        subject.shift(layout: &layout, index: 5)
        #expect(layout == originalLayout)
    }
}
