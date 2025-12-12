@testable import TTFreeCell
import Testing
import Foundation

private struct PersistenceTests {
    let subject = Persistence()
    let defaults = MockUserDefaults()

    init() {
        services.userDefaults = defaults
    }

    @Test("PrefKey raw values are correct")
    func prefKeyRawValues() {
        #expect(PrefKey.sequenceMoves.rawValue == "Sequence Moves")
        #expect(PrefKey.supermoves.rawValue == "Supermoves")
        #expect(PrefKey.showSequences.rawValue == "Show Sequences")
        #expect(PrefKey.growTappedCard.rawValue == "Grow Tapped Card")
        #expect(PrefKey.tintTappedCard.rawValue == "Tint Tapped Card")
        #expect(PrefKey.highlightDestinations.rawValue == "Highlight Destinations")
        #expect(PrefKey.automoveToFoundations.rawValue == "Automove To Foundations")
        #expect(PrefKey.earlyEndgame.rawValue == "Early Endgame")
        #expect(PrefKey.automoveOnFirstTap.rawValue == "Automove On First Tap")
        #expect(PrefKey.showClock.rawValue == "Show Clock")
    }

    @Test("PrefKey default keys are correct")
    func prefKeyDefaultKeys() {
        #expect(PrefKey.sequenceMoves.defaultKey == "sequenceMoves")
        #expect(PrefKey.supermoves.defaultKey == "supermoves")
        #expect(PrefKey.showSequences.defaultKey == "outlines")
        #expect(PrefKey.growTappedCard.defaultKey == "growTappedCard")
        #expect(PrefKey.tintTappedCard.defaultKey == "highlightTappedCard")
        #expect(PrefKey.highlightDestinations.defaultKey == "highlightDestinations")
        #expect(PrefKey.automoveToFoundations.defaultKey == "automoveToFoundations")
        #expect(PrefKey.earlyEndgame.defaultKey == "earlyEndgame")
        #expect(PrefKey.automoveOnFirstTap.defaultKey == "automoveToSole")
        #expect(PrefKey.showClock.defaultKey == "showClock")
    }

    @Test("PrefKey default values are correct")
    func prefKeyDefaultValues() {
        #expect(PrefKey.sequenceMoves.defaultValue == true)
        #expect(PrefKey.supermoves.defaultValue == true)
        #expect(PrefKey.showSequences.defaultValue == true)
        #expect(PrefKey.growTappedCard.defaultValue == true)
        #expect(PrefKey.tintTappedCard.defaultValue == false)
        #expect(PrefKey.highlightDestinations.defaultValue == true)
        #expect(PrefKey.automoveToFoundations.defaultValue == true)
        #expect(PrefKey.earlyEndgame.defaultValue == true)
        #expect(PrefKey.automoveOnFirstTap.defaultValue == true)
        #expect(PrefKey.showClock.defaultValue == true)
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

    @Test("loadLastMicrosoftDeal: returns int value for lastMicrosoftDeal")
    func loadLastMicrosoftDeal() {
        defaults.thingsToReturn["lastMicrosoftDeal"] = nil
        var result = subject.loadLastMicrosoftDeal()
        #expect(result == 0)
        #expect(defaults.methodsCalled == ["integer(forKey:)"])
        defaults.methodsCalled = []
        defaults.thingsToReturn["lastMicrosoftDeal"] = 1
        result = subject.loadLastMicrosoftDeal()
        #expect(result == 1)
        #expect(defaults.methodsCalled == ["integer(forKey:)"])
    }

    @Test("saveLastMicrosoftDeal: sets value for lastMicrosoftDeal")
    func saveLastMicrosoftDeal() {
        subject.saveLastMicrosoftDeal(42)
        #expect(defaults.methodsCalled == ["set(_:forKey:)"])
        #expect(defaults.thingsSet["lastMicrosoftDeal"] as? Int == 42)
    }

    @Test("loadPref: gets the correct pref value from user defaults and writes it into the pref and returns it")
    func loadPref() {
        defaults.thingsToReturn[PrefKey.sequenceMoves.defaultKey] = true
        var result = subject.loadPref(Pref(key: .sequenceMoves))
        #expect(defaults.methodsCalled == ["bool(forKey:)"])
        #expect(result.value == true)
        #expect(result.key == .sequenceMoves)
        defaults.thingsToReturn[PrefKey.sequenceMoves.defaultKey] = false
        defaults.methodsCalled = []
        result = subject.loadPref(Pref(key: .sequenceMoves))
        #expect(defaults.methodsCalled == ["bool(forKey:)"])
        #expect(result.value == false)
        #expect(result.key == .sequenceMoves)
        // and if key is not there (shouldn't happen), the result is false
        defaults.methodsCalled = []
        let pref = Pref(key: .automoveToFoundations, value: true)
        result = subject.loadPref(pref)
        #expect(defaults.methodsCalled == ["bool(forKey:)"])
        #expect(result.value == false)
        #expect(result.key == .automoveToFoundations)
    }

    @Test("savePref: saves the given pref value for the given pref's key's default key")
    func savePref() {
        subject.savePref(Pref(key: .automoveToFoundations, value: true))
        #expect(defaults.methodsCalled == ["set(_:forKey:)"])
        #expect(defaults.thingsSet[PrefKey.automoveToFoundations.defaultKey] as? Bool == true)
    }

    @Test("loadAnimationSpeed: converts double to speed, or no animation")
    func loadAnimationSpeed() {
        var result = subject.loadAnimationSpeed()
        #expect(defaults.methodsCalled == ["double(forKey:)"])
        #expect(result == .noAnimation)
        defaults.methodsCalled = []
        defaults.thingsToReturn["animations"] = 100.0
        result = subject.loadAnimationSpeed()
        #expect(defaults.methodsCalled == ["double(forKey:)"])
        #expect(result == .noAnimation)
        defaults.methodsCalled = []
        defaults.thingsToReturn["animations"] = 0.1
        result = subject.loadAnimationSpeed()
        #expect(defaults.methodsCalled == ["double(forKey:)"])
        #expect(result == .fast)
    }

    @Test("saveAnimationSpeed: saves the speed's raw value for animations")
    func saveAnimationSpeed() {
        subject.saveAnimationSpeed(.slow)
        #expect(defaults.methodsCalled == ["set(_:forKey:)"])
        #expect(defaults.thingsSet["animations"] as? Double == 0.3)
    }

    @Test("registerDefaults: writes all PrefKey default keys and default values, and animation speed ")
    func registerDefaults() {
        subject.registerDefaults()
        #expect(defaults.methodsCalled == ["register(defaults:)"])
        #expect(defaults.thingsSet["supermoves"] as? Bool == true)
        #expect(defaults.thingsSet["highlightDestinations"] as? Bool == true)
        #expect(defaults.thingsSet["highlightTappedCard"] as? Bool == false)
        #expect(defaults.thingsSet["outlines"] as? Bool == true)
        #expect(defaults.thingsSet["showClock"] as? Bool == true)
        #expect(defaults.thingsSet["automoveToFoundations"] as? Bool == true)
        #expect(defaults.thingsSet["earlyEndgame"] as? Bool == true)
        #expect(defaults.thingsSet["growTappedCard"] as? Bool == true)
        #expect(defaults.thingsSet["automoveToSole"] as? Bool == true)
        #expect(defaults.thingsSet["sequenceMoves"] as? Bool == true)
        #expect(defaults.thingsSet["animations"] as? Double == 0.3)
    }
}
