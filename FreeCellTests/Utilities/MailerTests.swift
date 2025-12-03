@testable import TTFreeCell
import Testing
import UIKit
import MessageUI

struct MailerTests {
    let subject = Mailer()

    init() {
        services.mailComposeViewControllerType = MockMailComposeViewController.self
    }

    @Test("mailViewController: returns MFComposeViewController with correct message and delegate")
    func mailViewController() throws {
        MockMailComposeViewController.calledCanSendMail = nil
        MockMailComposeViewController.canSendMailToReturn = true
        let result = try #require(subject.mailViewController(message: "howdy") as? MockMailComposeViewController)
        #expect(MockMailComposeViewController.calledCanSendMail == true)
        #expect(result.body == "howdy")
        #expect(result.isHTML == false)
        #expect(result.mailComposeDelegate === subject)
    }

    @Test("mailViewController: returns nil if cannot send mail")
    func mailViewControllerNoMail() throws {
        MockMailComposeViewController.calledCanSendMail = nil
        MockMailComposeViewController.canSendMailToReturn = false
        #expect(subject.mailViewController(message: "howdy") == nil)
    }

    @Test("delegate method calls dismiss")
    func delegateMethods() {
        // cannot test this, because I cannot create an actual MFMailComposeViewController to pass to it
    }
}

