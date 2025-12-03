import MessageUI

protocol MailComposeViewControllerType: UIViewController {
    init()
    var mailComposeDelegate: (any MFMailComposeViewControllerDelegate)? { get set }
    static func canSendMail() -> Bool
    func setMessageBody(_: String, isHTML: Bool)
}

extension MFMailComposeViewController: MailComposeViewControllerType {}
