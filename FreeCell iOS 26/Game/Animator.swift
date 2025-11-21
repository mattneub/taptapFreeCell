protocol AnimatorType {
    func animate(oldLayout: Layout, newLayout: Layout, speed: GameState.AnimationSpeed) async
}

/// Object that encapsulates the knowledge of how to construct and ask for an animation.
/// This isolates these rather wordy methods and makes testing a heck of lot easier.
final class Animator: AnimatorType {
    weak var processor: (any Processor<GameAction, GameState, GameEffect>)?

    init(processor: (any Processor<GameAction, GameState, GameEffect>)?) {
        self.processor = processor
    }

    /// Subroutine of `animate`. By comparing the old layout to the new layout, describe what
    /// has changed as an array of Moves, one per changed card. If a card does not change its
    /// location, it is not represented in the list of Moves.
    /// - Parameters:
    ///   - oldLayout: The old layout.
    ///   - newLayout: The new layout.
    /// - Returns: The list of moves describing how to move cards to change the old layout to
    /// the new layout.
    func calculateMoves(oldLayout: Layout, newLayout: Layout) -> [Move] {
        guard oldLayout != newLayout else {
            return []
        }
        let olds = oldLayout.allLocationsAndCards()
        let news = newLayout.allLocationsAndCards()
        let oldsDictionary: [Card: LocationAndCard] = olds.reduce(into: [:]) { dict, loc in
            dict[loc.card] = loc
        }
        let newsDictionary: [Card: LocationAndCard] = news.reduce(into: [:]) { dict, loc in
            dict[loc.card] = loc
        }
        if oldsDictionary.isEmpty { // special case: we are dealing! code Move with same locations
            return newsDictionary.values.map { Move(source: $0, destination: $0) }
        }
        var result = [Move]()
        for card in oldsDictionary.keys {
            if let oldLoc = oldsDictionary[card], let newLoc = newsDictionary[card] {
                if oldLoc != newLoc {
                    result.append(Move(source: oldLoc, destination: newLoc))
                }
            }
        }
        return result
    }

    /// Tell the presenter to perform an animation transforming the visible layout of cards
    /// from the old layout to the new layout.
    /// - Parameters:
    ///   - oldLayout: The old layout.
    ///   - newLayout: The new layout.
    ///   - speed: The animation speed.
    func animate(oldLayout: Layout, newLayout: Layout, speed: GameState.AnimationSpeed) async {
        guard speed != .noAnimation else {
            return
        }
        let moves = calculateMoves(oldLayout: oldLayout, newLayout: newLayout)
        await processor?.presenter?.receive(.animate(moves, duration: speed.rawValue))
    }

}
