import Foundation

final class ExportProcessor: Processor {
    weak var coordinator: (any RootCoordinatorType)?

    weak var presenter: (any ReceiverPresenter<Void, ExportState>)?

    weak var delegate: (any ExportDelegate)?

    var state = ExportState()

    func receive(_ action: ExportAction) async {
        switch action {
        case .cancel:
            await coordinator?.dismiss()
        case .export:
            await coordinator?.dismiss()
            delegate?.exportCurrentGame()
        case .import(let text):
            await coordinator?.dismiss()
            await delegate?.importGame(text)
        case .initialData:
            await presenter?.present(state)
        }
    }
}

protocol ExportDelegate: AnyObject {
    func exportCurrentGame()
    func importGame(_: String?) async
}
