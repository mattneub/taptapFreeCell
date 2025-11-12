struct GameState: Equatable {
    /// Source of truth for the game layout.
    var layout = Layout()

    /// Preferences
    var sequences = true
    var sequenceMoves = true
    var supermoves = true
    var tintTapped = true
    var growTapped = true

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

}
