@testable import FreeCell
import Testing
import Foundation

struct GameStateTests {
    @Test("gameIsOver is correct")
    func gameIsOver() {
        var subject = GameState()
        subject.layout.foundations[0].cards = [.init(rank: .queen, suit: .spades)]
        #expect(subject.gameIsOver == true)
        subject.layout.columns[0].cards = [.init(rank: .king, suit: .spades)]
        #expect(subject.gameIsOver == false)
        subject.layout.columns[0].cards = []
        subject.layout.freeCells[0].cards = [.init(rank: .king, suit: .spades)]
        #expect(subject.gameIsOver == false)
    }

    @Test("highlightOn is correct")
    func highlightOn() {
        var subject = GameState()
        #expect(subject.highlightOn == false)
        subject.firstTapLocation = .init(category: .column, index: 0)
        #expect(subject.highlightOn == true)
        subject.tintTapped = false
        subject.growTapped = false
        #expect(subject.highlightOn == false)
        subject.tintTapped = true
        subject.growTapped = false
        #expect(subject.highlightOn == true)
        subject.tintTapped = false
        subject.growTapped = true
        #expect(subject.highlightOn == true)
    }
}

