import Foundation

final class GameProcessor: Processor {
    weak var coordinator: (any RootCoordinatorType)?

    weak var presenter: (any ReceiverPresenter<GameEffect, GameState>)?

    var state = GameState()

    func receive(_ action: GameAction) async {}
}
