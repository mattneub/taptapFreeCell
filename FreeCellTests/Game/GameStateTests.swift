@testable import TTFreeCell
import Testing
import Foundation

private struct GameStateTests {
    @Test("gameIsOver is correct")
    func gameIsOver() {
        var subject = GameState()
        subject.layout.foundations[0].cards = [Card(rank: .queen, suit: .spades)]
        #expect(subject.gameIsOver == true)
        subject.layout.columns[0].cards = [Card(rank: .king, suit: .spades)]
        #expect(subject.gameIsOver == false)
        subject.layout.columns[0].cards = []
        subject.layout.freeCells[0].cards = [Card(rank: .king, suit: .spades)]
        #expect(subject.gameIsOver == false)
    }

    @Test("highlightOn is correct")
    func highlightOn() {
        var subject = GameState()
        #expect(subject.highlightOn == false)
        subject.firstTapLocation = Location(category: .column, index: 0)
        #expect(subject.highlightOn == true)
        subject[.tintTappedCard] = false
        subject[.growTappedCard] = false
        #expect(subject.highlightOn == false)
        subject[.tintTappedCard] = true
        subject[.growTappedCard] = false
        #expect(subject.highlightOn == true)
        subject[.tintTappedCard] = false
        subject[.growTappedCard] = true
        #expect(subject.highlightOn == true)
        subject[.tintTappedCard] = true
        subject[.growTappedCard] = true
        #expect(subject.highlightOn == true)
        subject[.tintTappedCard] = true
        subject[.growTappedCard] = true
        subject.firstTapLocation = nil
        #expect(subject.highlightOn == false)
    }

    @Test("subscripting works as expected")
    func subscripting() {
        var subject = GameState()
        subject.prefs = [.automoveOnFirstTap: true]
        #expect(subject[.automoveOnFirstTap] == true)
        #expect(subject[.earlyEndgame] == false)
        subject[.earlyEndgame] = true
        #expect(subject.prefs[.earlyEndgame] == true)
    }

    @Test("animation speed: cases are in correct order")
    func animationSpeed() {
        let result = GameState.AnimationSpeed.allCases
        #expect(result == [.fast, .slow, .glacial, .noAnimation])
    }
}

