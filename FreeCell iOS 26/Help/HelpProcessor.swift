import Foundation

final class HelpProcessor: Processor {
    weak var coordinator: (any RootCoordinatorType)?

    weak var presenter: (any ReceiverPresenter<HelpEffect, HelpState>)?

    /// State to be presented by the presenter. Whether it is rules or help will be set
    /// by the coordinator at module creation time; this initial value is a dummy.
    var state = HelpState(helpType: .rules)

    func receive(_ action: HelpAction) async {
        switch action {
        case .dismiss:
            await coordinator?.dismiss()
        case .goBack:
            if let name = state.undoStack.popLast() {
                await presenter?.receive(.navigate(to: name))
            }
            await presenter?.present(state)
        case .goLeft:
            await presenter?.receive(.goLeft)
            state.undoStack.removeAll()
            await presenter?.present(state)
        case .goRight:
            await presenter?.receive(.goRight)
            state.undoStack.removeAll()
            await presenter?.present(state)
        case .initialData:
            await presenter?.present(state)
        case .navigate(let target, let source):
            await presenter?.receive(.navigate(to: target))
            if let source {
                state.undoStack.append(source)
            }
            await presenter?.present(state)
        case .showSafari(let url):
            coordinator?.showSafari(url: url)
        case .userSwiped:
            state.undoStack.removeAll()
            await presenter?.present(state)
        }
    }
}
