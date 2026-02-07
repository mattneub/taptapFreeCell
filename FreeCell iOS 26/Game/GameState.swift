struct GameState: Equatable {
    /// Source of truth for the game layout.
    var layout = Layout()

    /// Secondary layout in "just dealt" condition, so that dealing on demand takes no time.
    var reserveLayout: Layout?

    var undoStack = [Layout]()
    var redoStack = [Layout]()

    /// Preferences
    var prefs: [PrefKey: Bool] = PrefKey.allCases.reduce(into: [:]) { result, prefKey in
        result[prefKey] = prefKey.defaultValue // initial value is simple the default default
    }
    var animationSpeed = AnimationSpeed.fast

    /// Subscript shorthand for accessing the prefs
    subscript(prefKey: PrefKey) -> Bool {
        get {
            prefs[prefKey] ?? false
        }
        set {
            prefs[prefKey] = newValue
        }
    }

    /// The game is always in one of two states: either the user has just performed the first
    /// tap of a two-tap sequence, or not. If so, and only if so, this is non-`nil`, and tells
    /// where the first tap was.
    var firstTapLocation: Location? = nil

    var gameProgress: GameProgress = .gameOver

    var gameIsOver: Bool {
        layout.numberOfCardsRemaining == 0
    }

    var highlightOn: Bool {
        (self[.tintTappedCard] || self[.growTappedCard]) && firstTapLocation != nil
    }

    var enablements = [Location: Enablement]()

    /// The base state of enablements is that all locations are normal.
    let baseEnablements: [Location: Enablement] = {
        var result = [Location: Enablement]()
        (0..<4).forEach {
            result[Location(category: .foundation, index: $0)] = .normal
            result[Location(category: .freeCell, index: $0)] = .normal
        }
        (0..<8).forEach {
            result[Location(category: .column, index: $0)] = .normal
        }
        return result
    }()

    enum Enablement {
        case disabled
        case enabled
        case normal
    }

    enum AnimationSpeed: Double, CaseIterable { // order matters! index == segment index
        case fast = 0.1
        case slow = 0.3
        case glacial = 0.5
        case noAnimation = 0.0
    }

    enum GameProgress {
        case dealtWaitingForFirstMove // dealt but no more; game started but stopwatch stopped
        case gameOver // between games; one game is finished, next game has not been dealt
        case inProgress // the user has made the first move, the stopwatch is watching
    }
}
