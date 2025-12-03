import UIKit
@testable import TTFreeCell
import MessageUI

final class MockMailComposeViewController: UIViewController, MailComposeViewControllerType {
    var methodsCalled = [String]()
    var body: String?
    var isHTML: Bool?
    static var calledCanSendMail: Bool?
    static var canSendMailToReturn = false

    var mailComposeDelegate: (any MFMailComposeViewControllerDelegate)?

    func setMessageBody(_ body: String, isHTML: Bool) {
        methodsCalled.append(#function)
        self.body = body
        self.isHTML = isHTML
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        methodsCalled.append(#function)
    }

    static func canSendMail() -> Bool {
        self.calledCanSendMail = true
        return canSendMailToReturn
    }
}

