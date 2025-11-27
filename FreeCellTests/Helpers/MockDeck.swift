@testable import TTFreeCell
import Foundation

final class MockDeck: DeckType {
    var methodsCalled = [String]()
    var cardsToDeal = [Card]()

    // gated by shuffle and deal to behave as if a deck consists of exactly one card
    var isEmpty = false

    func shuffle() {
        methodsCalled.append(#function)
        isEmpty = false
    }
    
    func deal() -> Card {
        methodsCalled.append(#function)
        isEmpty = true
        return cardsToDeal.removeFirst()
    }

}
