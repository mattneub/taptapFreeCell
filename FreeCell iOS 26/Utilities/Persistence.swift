import Foundation

struct Defaults {
    static let currentGame = "currentGame"
    static let didMigration3 = "migration3"
    static let stats = "stats" // actually, this one keys into Documents
    static let lastMicrosoftDeal = "lastMicrosoftDeal"
    static let animations = "animations"
}

enum PrefKey: String, Hashable, CaseIterable {
    case sequenceMoves = "Sequence Moves"
    case supermoves = "Supermoves"
    case showSequences = "Show Sequences"
    case growTappedCard = "Grow Tapped Card"
    case tintTappedCard = "Tint Tapped Card"
    case highlightDestinations = "Highlight Destinations"
    case automoveToFoundations = "Automove To Foundations"
    case earlyEndgame = "Early Endgame"
    case automoveOnFirstTap = "Automove On First Tap"
    case showClock = "Show Clock"

    /// The key string to be used in persistence. Some of these may look a little odd,
    /// but it's too late to change them now; these are the keys people already have
    /// in their user defaults, so we have to match them perfectly.
    var defaultKey: String {
        switch self {
        case .sequenceMoves:
            "sequenceMoves"
        case .supermoves:
            "supermoves"
        case .showSequences:
            "outlines"
        case .growTappedCard:
            "growTappedCard"
        case .tintTappedCard:
            "highlightTappedCard"
        case .highlightDestinations:
            "highlightDestinations"
        case .automoveToFoundations:
            "automoveToFoundations"
        case .earlyEndgame:
            "earlyEndgame"
        case .automoveOnFirstTap:
            "automoveToSole"
        case .showClock:
            "showClock"
        }
    }

    /// The default value to be registered into user defaults at launch.
    var defaultValue: Bool {
        switch self {
        case .sequenceMoves:
            true
        case .supermoves:
            true
        case .showSequences:
            true
        case .growTappedCard:
            true
        case .tintTappedCard:
            false
        case .highlightDestinations:
            true
        case .automoveToFoundations:
            true
        case .earlyEndgame:
            true
        case .automoveOnFirstTap:
            true
        case .showClock:
            true
        }
    }

    /// The value that is our subordinate. If we become false, it must become false.
    var hasSubordinate: PrefKey? {
        switch self {
        case .sequenceMoves: .supermoves
        case .automoveToFoundations: .earlyEndgame
        default: nil
        }
    }

    /// The value to which we are subordinate (inverse of the preceding). If we become true,
    /// it must become true.
    var isSubordinateTo: PrefKey? {
        switch self {
        case .supermoves: .sequenceMoves
        case .earlyEndgame: .automoveToFoundations
        default: nil
        }
    }
}

struct SavedGame: Codable, Equatable {
    let layout: Layout
    let undoStack: [Layout]
    let redoStack: [Layout]
    let timeTaken: TimeInterval
}

protocol PersistenceType: Sendable {
    func saveGame(_: SavedGame)
    func loadGame() -> SavedGame?
    func setDidMigration3(_: Bool)
    func didMigration3() -> Bool
    func loadLastMicrosoftDeal() -> Int
    func saveLastMicrosoftDeal(_: Int)

    // just hand me the whole pref and let me worry about the details
    func loadPref(_: Pref) -> Pref
    func savePref(_: Pref)

    func loadAnimationSpeed() -> GameState.AnimationSpeed
    func saveAnimationSpeed(_: GameState.AnimationSpeed)

    func registerDefaults()
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

    func loadLastMicrosoftDeal() -> Int {
        services.userDefaults.integer(forKey: Defaults.lastMicrosoftDeal)
    }

    func saveLastMicrosoftDeal(_ int: Int) {
        services.userDefaults.set(int, forKey: Defaults.lastMicrosoftDeal)
    }

    func loadPref(_ pref: Pref) -> Pref {
        var pref = pref
        pref.value = services.userDefaults.bool(forKey: pref.key.defaultKey)
        return pref
    }

    func savePref(_ pref: Pref) {
        services.userDefaults.set(pref.value, forKey: pref.key.defaultKey)
    }

    func loadAnimationSpeed() -> GameState.AnimationSpeed {
        GameState.AnimationSpeed(rawValue: services.userDefaults.double(forKey: Defaults.animations)) ?? .noAnimation
    }

    func saveAnimationSpeed(_ speed: GameState.AnimationSpeed) {
        services.userDefaults.set(speed.rawValue, forKey: Defaults.animations)
    }

    func registerDefaults() {
        var dictionary = [String: Any]()
        for prefKey in PrefKey.allCases {
            dictionary[prefKey.defaultKey] = prefKey.defaultValue
        }
        dictionary[Defaults.animations] = 0.3
        services.userDefaults.register(defaults: dictionary)
    }
}
