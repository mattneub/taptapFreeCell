import Foundation

final class GameProcessor: Processor {
    weak var coordinator: (any RootCoordinatorType)?

    weak var presenter: (any ReceiverPresenter<GameEffect, GameState>)?

    var state = GameState()

    func receive(_ action: GameAction) async {
        switch action {
        case .autoplay:
            await autoplay()
        case .deal:
            var deck = Deck()
            deck.shuffle()
            state.layout.deal(deck)
            state.firstTapLocation = nil
            // TODO: unhighlight as needed
            await presenter?.present(state)
        case .tapBackground:
            state.firstTapLocation = nil
            // TODO: unhighlight as needed
            await presenter?.present(state)
        case .tapped(let tap):
            if state.firstTapLocation == nil {
                await handleFirstTap(tap)
            } else {
                await handleSecondTap(tap)
            }
        }
    }

    func playToFoundationIfSafeAndPossible(location: Location) -> Bool {
        if let card = state.layout.card(at: location) {
            if card.canGoOn(state.layout.foundations) {
                if !state.layout.mightNeed(card: card) {
                    let card = state.layout.surrenderCard(from: location)
                    state.layout.foundations.accept(card: card)
                    return true
                }
            }
        }
        return false
    }

    func autoplay() async {
        var moved = false
        let locations: [Location] = (
            (0..<8).map { Location(category: .column, index: $0) } +
            (0..<4).map { Location(category: .freeCell, index: $0) }
        )
        repeat {
            moved = false
            for location in locations {
                if playToFoundationIfSafeAndPossible(location: location) {
                    moved = true
                }
            }
        } while moved
        state.firstTapLocation = nil
        // TODO: unhighlight as needed
        await presenter?.present(state)
    }

    func handleFirstTap(_ location: Location) async {
        guard state.layout.card(at: location) != nil else {
            return // first tap can never be on an empty
        }
        guard location.category != .foundation else {
            return // first tap can never be on a foundation
        }
        // if card can be autoplayed, autoplay it immediately
        // TODO: should probably make this a separate pref
        if playToFoundationIfSafeAndPossible(location: location) {
            await presenter?.present(state)
            return
        }
        state.firstTapLocation = location
        await presenter?.present(state) // to cause highlighting
    }

    func handleSecondTap(_ secondTapLocation: Location) async {
        guard let firstTapLocation = state.firstTapLocation else {
            return // shouldn't happen
        }
        guard let card = state.layout.card(at: firstTapLocation) else {
            return // shouldn't happen
        }
        switch secondTapLocation.category {
        case .foundation:
            // doesn't matter which foundation was tapped; if it can move, move it
            if card.canGoOn(state.layout.foundations) {
                let card = state.layout.surrenderCard(from: firstTapLocation)
                state.layout.foundations.accept(card: card)
            }
        case .freeCell:
            // doesn't matter which free cell was tapped; if it can move, move to first empty
            guard firstTapLocation.category == .column else {
                break // only a column can be moved to a free cell
            }
            guard let targetIndex = state.layout.indexOfFirstEmptyFreeCell else {
                break // we need a free cell to move to
            }
            let card = state.layout.surrenderCard(from: firstTapLocation)
            state.layout.freeCells[targetIndex].accept(card: card)
        case .column:
            switch firstTapLocation.category {
            case .foundation: break // shouldn't happen
            case .freeCell:
                if card.canGoOn(state.layout.columns[secondTapLocation.index]) {
                    let card = state.layout.surrenderCard(from: firstTapLocation)
                    state.layout.columns[secondTapLocation.index].accept(card: card)
                }
            case .column:
                let movableCount = state.layout.howManyCardsCanMove(
                    from: firstTapLocation.index,
                    to: secondTapLocation.index,
                    sequenceMoves: state.sequenceMoves,
                    supermoves: state.supermoves
                )
                if state.layout.columns[secondTapLocation.index].isEmpty {
                    if state.layout.columns[firstTapLocation.index].cards.count == movableCount {
                        break // meaningless to move all the cards from a column to an empty column
                    }
                }
                if movableCount > 0 {
                    state.layout.columns[firstTapLocation.index].cards.suffix(movableCount).forEach {
                        state.layout.columns[secondTapLocation.index].accept(card: $0)
                    }
                    state.layout.columns[firstTapLocation.index].cards.removeLast(movableCount)
                }
            }
        }
        state.firstTapLocation = nil
        await presenter?.present(state)
    }
}
