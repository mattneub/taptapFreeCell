import UIKit

final class GameViewController: UIViewController, ReceiverPresenter {
    weak var processor: (any Receiver<GameAction>)?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func present(_ state: GameState) async {}

    func receive(_ effect: GameEffect) async {}
}
