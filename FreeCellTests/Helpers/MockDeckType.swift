@testable import TTFreeCell
import Foundation

final class MockDeckFactory: DeckFactoryType {
    var mockDeckToReturn = MockDeck()
    func makeDeck() -> any DeckType {
        return mockDeckToReturn
    }
}
