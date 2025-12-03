import UIKit
import MessageUI

protocol MailerType {
    func mailViewController(message: String) -> UIViewController?
}

final class Mailer: NSObject, MailerType {
    func mailViewController(message: String) -> UIViewController? {
        guard services.mailComposeViewControllerType.canSendMail() else {
            return nil
        }
        let viewController = services.mailComposeViewControllerType.init()
        viewController.setMessageBody(message, isHTML: false)
        viewController.mailComposeDelegate = self
        return viewController
    }
}

extension Mailer: MFMailComposeViewControllerDelegate {
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: (any Error)?
    ) {
        controller.dismiss(animated: unlessTesting(true))
    }
}
