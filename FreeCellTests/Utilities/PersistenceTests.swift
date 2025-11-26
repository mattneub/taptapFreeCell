@testable import TTFreeCell
import Testing
import Foundation

struct PersistenceTests {
    let subject = Persistence()
    let defaults = MockUserDefaults()

    init() {
        services.userDefaults = defaults
    }

    @Test("saveGame: encodes game using property list encoder, calls set for currentGame")
    func saveGame() throws {
        var layout = Layout()
        layout.foundations[0].cards = [Card(rank: .six, suit: .spades)] // *
        let savedGame = SavedGame(
            layout: layout,
            undoStack: [Layout(), Layout(), Layout()],
            redoStack: [Layout(), Layout()],
            timeTaken: 3
        )
        subject.saveGame(savedGame)
        #expect(defaults.methodsCalled == ["set(_:forKey:)"])
        let data = try #require(defaults.thingsSet["currentGame"] as? Data)
        let result = try PropertyListDecoder().decode(SavedGame.self, from: data)
        #expect(result == savedGame)
    }

    @Test("loadGame: calls object for currentGame, decodes and returns")
    func loadGame() throws {
        var layout = Layout()
        layout.foundations[0].cards = [Card(rank: .six, suit: .spades)] // *
        let savedGame = SavedGame(
            layout: layout,
            undoStack: [Layout(), Layout(), Layout()],
            redoStack: [Layout(), Layout()],
            timeTaken: 3
        )
        let data = try PropertyListEncoder().encode(savedGame)
        defaults.thingsToReturn["currentGame"] = data
        let result = try #require(subject.loadGame())
        #expect(defaults.methodsCalled == ["data(forKey:)"])
        #expect(result == savedGame)
    }

    @Test("loadGame: calls object for currentGame, returns nil if not there or not saved game")
    func loadGameBad() throws {
        let result = subject.loadGame()
        #expect(result == nil)
        defaults.thingsToReturn["currentGame"] = Data()
        let result2 = subject.loadGame()
        #expect(result2 == nil)
    }

    @Test("setDidMigration3: sets bool value for migration3")
    func setDidMigration3() {
        subject.setDidMigration3(true)
        #expect(defaults.methodsCalled == ["set(_:forKey:)"])
        #expect(defaults.thingsSet["migration3"] as? Bool == true)
        defaults.methodsCalled = []
        subject.setDidMigration3(false)
        #expect(defaults.methodsCalled == ["set(_:forKey:)"])
        #expect(defaults.thingsSet["migration3"] as? Bool == false)
    }

    @Test("didMigration3: returns bool value for migration3")
    func didMigration3() {
        defaults.thingsToReturn["migration3"] = false
        var result = subject.didMigration3()
        #expect(result == false)
        #expect(defaults.methodsCalled == ["bool(forKey:)"])
        defaults.methodsCalled = []
        defaults.thingsToReturn["migration3"] = true
        result = subject.didMigration3()
        #expect(result == true)
        #expect(defaults.methodsCalled == ["bool(forKey:)"])
    }

}
