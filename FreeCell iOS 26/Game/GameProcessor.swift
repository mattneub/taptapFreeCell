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
            state.firstTap = nil
            // TODO: unhighlight as needed
            await presenter?.present(state)
        case .tapBackground:
            state.firstTap = nil
            // TODO: unhighlight as needed
            await presenter?.present(state)
        case .tapped(let tap):
            if state.firstTap == nil {
                await handleFirstTap(tap)
            } else {
                await handleSecondTap(tap)
            }
        }
    }

    func autoplay() async {
        var columns = state.layout.columns
        var freeCells = state.layout.freeCells
        var moved = false
        repeat {
            moved = false
            columns.modifyEach { column in
                if let bottom = column.bottom {
                    if bottom.canGoOn(state.layout.foundations) {
                        if !state.layout.mightNeed(card: bottom) {
                            let card = column.surrenderCard()
                            state.layout.foundations.accept(card: card)
                            moved = true
                        }
                    }
                }
            }
            freeCells.modifyEach { freeCell in
                if let card = freeCell.card {
                    if card.canGoOn(state.layout.foundations) {
                        if !state.layout.mightNeed(card: card) {
                            let card = freeCell.surrenderCard()
                            state.layout.foundations.accept(card: card)
                            moved = true
                        }
                    }
                }
            }
        } while moved
        state.layout.columns = columns
        state.layout.freeCells = freeCells
        state.firstTap = nil
        // TODO: unhighlight as needed
        await presenter?.present(state)
    }

    func handleFirstTap(_ tap: Tap) async {
        guard let card = state.layout.card(for: tap) else {
            return // first tap can never be on an empty
        }
        switch tap.category {
        case .foundation:
            return // first tap can never be on a foundation
        default: break
        }
        // if card can be autoplayed, autoplay it immediately
        // TODO: should probably make this a separate pref
        if card.canGoOn(state.layout.foundations) {
            if !state.layout.mightNeed(card: card) {
                let card = state.layout.surrenderCard(for: tap)
                state.layout.foundations.accept(card: card)
                await presenter?.present(state)
                return
            }
        }
        state.firstTap = tap
        // TODO: highlighting should happen here
    }

    func handleSecondTap(_ secondTap: Tap) async {
        guard let firstTap = state.firstTap else {
            return // shouldn't happen
        }
        guard let card = state.layout.card(for: firstTap) else {
            return // shouldn't happen
        }
        switch secondTap.category {
        case .foundation:
            // doesn't matter which foundation was tapped; if it can move, move it
            if card.canGoOn(state.layout.foundations) {
                let card = state.layout.surrenderCard(for: firstTap)
                state.layout.foundations.accept(card: card)
            }
        case .freeCell:
            // doesn't matter which free cell was tapped; if it can move, move to first empty
            guard firstTap.category == .column else {
                break // only a column can be moved to a free cell
            }
            guard let targetIndex = state.layout.indexOfFirstEmptyFreeCell else {
                break // we need a free cell to move to
            }
            let card = state.layout.surrenderCard(for: firstTap)
            state.layout.freeCells[targetIndex].accept(card: card)
        case .column:
            switch firstTap.category {
            case .foundation: break // shouldn't happen
            case .freeCell:
                if card.canGoOn(state.layout.columns[secondTap.index]) {
                    let card = state.layout.surrenderCard(for: firstTap)
                    state.layout.columns[secondTap.index].accept(card: card)
                }
            case .column:
                let movableCount = state.layout.howManyCardsCanMove(
                    from: firstTap.index,
                    to: secondTap.index,
                    sequenceMoves: state.sequenceMoves,
                    supermoves: state.supermoves
                )
                if movableCount > 0 {
                    state.layout.columns[firstTap.index].cards.suffix(movableCount).forEach {
                        state.layout.columns[secondTap.index].accept(card: $0)
                    }
                    state.layout.columns[firstTap.index].cards.removeLast(movableCount)
                }
            }
        }
        state.firstTap = nil
        // TODO: unhighlighting should happen here
        await presenter?.present(state)
    }
}
