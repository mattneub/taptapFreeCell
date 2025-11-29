import Foundation

final class StatsProcessor: Processor {
    weak var coordinator: (any RootCoordinatorType)?

    weak var presenter: (any ReceiverPresenter<StatsEffect, StatsState>)?

    var state = StatsState()

    func receive(_ action: StatsAction) async {
        switch action {
        case .initialData:
            let stats = await services.stats.stats
            state.stats = stats
            await presenter?.present(state)
        case .totalChanged(let total, let won):
            await presenter?.receive(.totalChanged(total: total, won: won))
        }
    }
}
