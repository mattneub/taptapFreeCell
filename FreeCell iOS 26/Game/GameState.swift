struct GameState: Equatable {
    /// Source of truth for the game layout.
    var layout = Layout()

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
            result[.init(category: .foundation, index: $0)] = .normal
            result[.init(category: .freeCell, index: $0)] = .normal
        }
        (0..<8).forEach {
            result[.init(category: .column, index: $0)] = .normal
        }
        return result
    }()

    enum Enablement {
        case disabled
        case enabled
        case normal
    }
}
