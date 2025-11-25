@testable import TTFreeCell
import UIKit

final class MockPersistence: PersistenceType {
    var methodsCalled = [String]()
    var savedGame: SavedGame?
    var savedGameToReturn: SavedGame?

    func saveGame(_ savedGame: SavedGame) {
        methodsCalled.append(#function)
        self.savedGame = savedGame
    }
    
    func loadGame() -> SavedGame? {
        methodsCalled.append(#function)
        return savedGameToReturn
    }

}
