@testable import TTFreeCell
import UIKit

final class MockGameViewMenuBuilder: GameViewMenuBuilderType {
    var methodsCalled = [String]()
    var processor: (any Receiver<GameAction>)?

    func buildMenu(processor: (any Receiver<GameAction>)?) -> UIMenu {
        methodsCalled.append(#function)
        self.processor = processor
        return UIMenu(title: "title")
    }
}

