import Foundation

final class PrefsProcessor: Processor {
    weak var coordinator: (any RootCoordinatorType)?

    weak var presenter: (any ReceiverPresenter<Void, PrefsState>)?

    var state = PrefsState()

    func receive(_ action: PrefsAction) async {}
}
