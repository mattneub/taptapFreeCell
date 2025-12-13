import Foundation

final class PrefsProcessor: Processor {
    weak var coordinator: (any RootCoordinatorType)?

    weak var presenter: (any ReceiverPresenter<PrefsEffect, PrefsState>)?

    weak var delegate: (any PrefsDelegate)?

    var state = PrefsState()

    func receive(_ action: PrefsAction) async {
        switch action {
        case .initialData:
            await presenter?.present(state)
        case .prefChanged(let prefKey, let value):
            await delegate?.prefChanged(prefKey, value: value)
            await presenter?.receive(.prefChanged(prefKey, value: value))
            if let superordinate = prefKey.isSubordinateTo, value == true {
                await delegate?.prefChanged(superordinate, value: true)
                await presenter?.receive(.prefChanged(superordinate, value: true))
            } else if let subordinate = prefKey.hasSubordinate, value == false {
                await delegate?.prefChanged(subordinate, value: false)
                await presenter?.receive(.prefChanged(subordinate, value: false))
            }
        case .speedChanged(let index):
            await delegate?.speedChanged(index: index)
            await presenter?.receive(.speedChanged(index: index))
        }
    }
}

protocol PrefsDelegate: AnyObject {
    func prefChanged(_: PrefKey, value: Bool) async
    func speedChanged(index: Int) async
}
