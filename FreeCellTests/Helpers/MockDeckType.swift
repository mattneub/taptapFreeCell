@testable import TTFreeCell
import Foundation

final class MockDeckFactory: DeckFactoryType {
    nonisolated(unsafe) var mockDeckToReturn = MockDeck()
    func makeDeck() -> any DeckType {
        return mockDeckToReturn
    }
}
