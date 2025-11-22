import Foundation

struct Defaults {
    static let currentGame = "currentGame"
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
}
