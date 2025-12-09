@testable import TTFreeCell
import UIKit

final class MockPersistence: PersistenceType {
    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var savedGame: SavedGame?
    nonisolated(unsafe) var savedGameToReturn: SavedGame?
    nonisolated(unsafe) var migrationSet: Bool?
    nonisolated(unsafe) var migrationToReturn: Bool?
    nonisolated(unsafe) var microsoftDealSet: Int?
    nonisolated(unsafe) var microsoftDealToReturn: Int?

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

    func loadLastMicrosoftDeal() -> Int {
        methodsCalled.append(#function)
        return microsoftDealToReturn ?? 0
    }

    func saveLastMicrosoftDeal(_ deal: Int) {
        methodsCalled.append(#function)
        microsoftDealSet = deal
    }



}
