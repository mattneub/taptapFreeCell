import Foundation

final class MicrosoftProcessor: Processor {
    weak var coordinator: (any RootCoordinatorType)?

    weak var presenter: (any ReceiverPresenter<Void, MicrosoftState>)?

    weak var delegate: (any MicrosoftDelegate)?

    var state = MicrosoftState()

    func receive(_ action: MicrosoftAction) async {
        switch action {
        case .cancel:
            await coordinator?.dismiss()
        case .deal:
            services.persistence.saveLastMicrosoftDeal(state.currentDealNumber)
            await coordinator?.dismiss()
            await delegate?.dealMicrosoftNumber(state.currentDealNumber)
        case .initialData:
            let lastDeal = max(services.persistence.loadLastMicrosoftDeal(), 1)
            state.currentDealNumber = lastDeal
            let stats = await services.stats.stats
            let previousDeals = Set(stats.compactMap { $0.value.microsoftDealNumber })
            state.previousDeals = previousDeals
            await presenter?.present(state)
        case .stepper(let value):
            state.currentDealNumber = Int(value)
            await presenter?.present(state)
        case .userTyped(let value):
            state.currentDealNumber = value
            await presenter?.present(state)
        }
    }
}

protocol MicrosoftDelegate: AnyObject {
    func dealMicrosoftNumber(_: Int) async
}
