import UIKit
@testable import TTFreeCell

final class MockRootCoordinator: RootCoordinatorType {
    var methodsCalled = [String]()
    var window: UIWindow?
    var title: String?
    var message: String?
    var buttonTitles = [String]()
    var buttonTitleToReturn: String?
    var stat: Stat?

    func createInterface(window: UIWindow) {
        methodsCalled.append(#function)
        self.window = window
    }

    func showAlert(title: String?, message: String?, buttonTitles: [String]) async -> String? {
        methodsCalled.append(#function)
        self.title = title
        self.message = message
        self.buttonTitles = buttonTitles
        return buttonTitleToReturn
    }

    func showStats() {
        methodsCalled.append(#function)
    }

    func popToGame() {
        methodsCalled.append(#function)
    }

    func showMail(message: String) {
        methodsCalled.append(#function)
        self.message = message
    }

    func showPreview(stat: Stat) async {
        methodsCalled.append(#function)
        self.stat = stat
    }

}
