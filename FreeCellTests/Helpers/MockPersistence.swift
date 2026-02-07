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
    nonisolated(unsafe) var prefsSet = [PrefKey: Bool]()
    nonisolated(unsafe) var prefsToReturn = [PrefKey: Bool]()
    nonisolated(unsafe) var speedSet: GameState.AnimationSpeed?
    nonisolated(unsafe) var speedToReturn: GameState.AnimationSpeed?
    nonisolated(unsafe) var layoutSet: Layout?
    nonisolated(unsafe) var layoutToReturn: Layout?

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

    func loadPref(_ pref: Pref) -> Pref {
        methodsCalled.append(#function)
        return Pref(key: pref.key, value: prefsToReturn[pref.key] ?? false)
    }

    func savePref(_ pref: Pref) {
        methodsCalled.append(#function)
        prefsSet[pref.key] = pref.value
    }

    func loadAnimationSpeed() -> GameState.AnimationSpeed {
        methodsCalled.append(#function)
        return speedToReturn ?? .noAnimation
    }

    func saveAnimationSpeed(_ speed: GameState.AnimationSpeed) {
        methodsCalled.append(#function)
        speedSet = speed
    }

    func registerDefaults() {
        methodsCalled.append(#function)
    }

    func loadReserveLayout() -> Layout? {
        methodsCalled.append(#function)
        return layoutToReturn
    }

    func saveReserveLayout(_ layout: Layout?) {
        methodsCalled.append(#function)
        layoutSet = layout
    }



}
