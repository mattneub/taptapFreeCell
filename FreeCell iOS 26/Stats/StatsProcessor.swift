import Foundation

final class StatsProcessor: Processor {
    weak var coordinator: (any RootCoordinatorType)?

    weak var presenter: (any ReceiverPresenter<StatsEffect, StatsState>)?

    weak var delegate: (any StatsDelegate)?

    var state = StatsState()

    func receive(_ action: StatsAction) async {
        switch action {
        case .delete(let key):
            try? await services.stats.delete(key: key)
            let stats = await services.stats.stats
            state.stats = stats
        case .initialData:
            let stats = await services.stats.stats
            state.stats = stats
            await presenter?.present(state)
        case .mail(let stat):
            let message = services.exporter.messageText(layout: stat.initialLayout, moves: stat.codes)
            coordinator?.showMail(message: message)
        case .resume(let key):
            let reply = await coordinator?.showAlert(
                title: "Resume Lost Game",
                message: "Resume playing lost game?",
                buttonTitles: ["Cancel", "Resume"]
            )
            if reply == "Resume", let stat = state.stats[key] {
                await delegate?.resume(stat: stat)
            }
        case .snapshot(let stat):
            await coordinator?.showPreview(stat: stat)
        case .totalChanged(let total, let won):
            await presenter?.receive(.totalChanged(total: total, won: won))
        }
    }
}

protocol StatsDelegate: AnyObject {
    func resume(stat: Stat) async
}
