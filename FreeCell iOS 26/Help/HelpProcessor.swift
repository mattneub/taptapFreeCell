import Foundation

final class HelpProcessor: Processor {
    weak var coordinator: (any RootCoordinatorType)?

    weak var presenter: (any ReceiverPresenter<HelpEffect, HelpState>)?

    /// State to be presented by the presenter. Whether it is rules or help will be set
    /// by the coordinator at module creation time; this initial value is a dummy.
    var state = HelpState(helpType: .rules)

    func receive(_ action: HelpAction) async {
        switch action {
        case .goLeft:
            await presenter?.receive(.goLeft)
        case .goRight:
            await presenter?.receive(.goRight)
        case .initialData:
            await presenter?.present(state)
        case .navigate(let name):
            await presenter?.receive(.navigate(to: name))
        case .showSafari(let url):
            coordinator?.showSafari(url: url)
        }
    }
}
