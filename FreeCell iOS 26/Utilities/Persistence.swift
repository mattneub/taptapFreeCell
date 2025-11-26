import Foundation

struct Defaults {
    static let currentGame = "currentGame"
    static let didMigration3 = "migration3"
    static let stats = "stats" // actually, this one keys into Documents
}

struct SavedGame: Codable, Equatable {
    let layout: Layout
    let undoStack: [Layout]
    let redoStack: [Layout]
    let timeTaken: TimeInterval
}

protocol PersistenceType {
    func saveGame(_: SavedGame)
    func loadGame() -> SavedGame?
    func setDidMigration3(_: Bool)
    func didMigration3() -> Bool
}

final class Persistence: PersistenceType {
    func saveGame(_ game: SavedGame) {
        if let data = try? PropertyListEncoder().encode(game) {
            services.userDefaults.set(data, forKey: Defaults.currentGame)
        }
    }

    func loadGame() -> SavedGame? {
        if let data = services.userDefaults.data(forKey: Defaults.currentGame) {
            return try? PropertyListDecoder().decode(SavedGame.self, from: data)
        }
        return nil
    }

    func setDidMigration3(_ bool: Bool) {
        services.userDefaults.set(bool, forKey: Defaults.didMigration3)
    }

    func didMigration3() -> Bool {
        return services.userDefaults.bool(forKey: Defaults.didMigration3)
    }

}
