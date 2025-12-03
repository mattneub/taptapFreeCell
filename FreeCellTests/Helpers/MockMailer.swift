import UIKit
@testable import TTFreeCell

final class MockMailer: MailerType {
    var methodsCalled = [String]()
    var message: String?
    var viewControllerToReturn: UIViewController?

    func mailViewController(message: String) -> UIViewController? {
        methodsCalled.append(#function)
        self.message = message
        return viewControllerToReturn
    }
}
