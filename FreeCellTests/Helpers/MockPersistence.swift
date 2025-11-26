@testable import TTFreeCell
import UIKit

final class MockPersistence: PersistenceType {
    var methodsCalled = [String]()
    var savedGame: SavedGame?
    var savedGameToReturn: SavedGame?
    var migrationSet: Bool?
    var migrationToReturn: Bool?

    func saveGame(_ savedGame: SavedGame) {
        methodsCalled.append(#function)
        self.savedGame = savedGame
    }
    
    func loadGame() -> SavedGame? {
        methodsCalled.append(#function)
        return savedGameToReturn
    }

    func setDidMigration3(_ migration: Bool) {
        methodsCalled.append(#function)
        migrationSet = migration
    }

    func didMigration3() -> Bool {
        methodsCalled.append(#function)
        return migrationToReturn ?? false
    }


}
