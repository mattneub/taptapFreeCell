@testable import FreeCell
import UIKit

final class MockGameViewMenuBuilder: GameViewMenuBuilderType {
    var methodsCalled = [String]()

    func buildMenu() -> UIMenu {
        methodsCalled.append(#function)
        return UIMenu(title: "title")
    }
}

