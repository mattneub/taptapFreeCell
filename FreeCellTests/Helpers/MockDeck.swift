@testable import TTFreeCell
import Foundation

final class MockDeck: DeckType {
    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var cardsToDeal = [Card]()

    // gated by shuffle and deal to behave as if a deck consists of exactly one card
    nonisolated(unsafe) var isEmpty = false

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
