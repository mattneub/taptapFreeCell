struct GameState: Equatable {
    /// Source of truth for the game layout.
    var layout = Layout()

    var undoStack = [Layout]()
    var redoStack = [Layout]()

    /// Preferences
    var sequences = true
    var sequenceMoves = true
    var supermoves = true
    var tintTapped = false
    var growTapped = true
    var showDestinations = true
    var autoplay = true
    var unambiguousMove = true

    /// The game is always in one of two states: either the user has just performed the first
    /// tap of a two-tap sequence, or not. If so, and only if so, this is non-`nil`, and tells
    /// where the first tap was.
    var firstTapLocation: Location? = nil

    /// We need to know, when the game is over, whether this is the _first_ time we have
    /// discovered that it was over. So this variable lets us record that we already
    /// knew that the game was over; if the game is underway we set it to true, and when
    /// we learn that the game is over we set it to false.
    var gameInProgress = false

    var gameIsOver: Bool {
        layout.numberOfCardsRemaining == 0
    }

    var highlightOn: Bool {
        (tintTapped || growTapped) && firstTapLocation != nil
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
}
