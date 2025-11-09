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
            await presenter?.present(state)
        }
    }

    func autoplay() async {
        var columns = state.layout.columns
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
        } while moved
        state.layout.columns = columns
        await presenter?.present(state)
    }
}
