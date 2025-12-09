@testable import TTFreeCell
import Testing
import UIKit
import SnapshotTesting
import WaitWhile

private struct MicrosoftViewControllerTests {
    let subject = MicrosoftViewController(nibName: "Microsoft", bundle: nil)
    let processor = MockReceiver<MicrosoftAction>()

    init() {
        subject.processor = processor
    }

    @Test("preferred content size is correct")
    func preferredContentSize() {
        #expect(subject.preferredContentSize == CGSize(width: 250, height: 220))
    }

    @Test("dimming view is correctly constructed")
    func dimmingView() {
        let view = subject.dimmingView
        #expect(view.backgroundColor == .black.withAlphaComponent(0.2))
        #expect(view.autoresizingMask == [.flexibleWidth, .flexibleHeight])
        #expect(view.alpha == 0)
    }

    @Test("viewDidLoad configures things correctly, sends processor initialData; looks correct")
    func viewDidLoad() async {
        let viewController = UIViewController()
        makeWindow(viewController: viewController)
        viewController.view.addSubview(subject.view)
        viewController.view.layoutIfNeeded()
        subject.view.frame = CGRect(origin: .zero, size: subject.preferredContentSize)
        #expect(subject.view.backgroundColor == .systemBackground)
        #expect(subject.contentView.backgroundColor == .tertiarySystemBackground)
        #expect(subject.dealStepper.cornerConfiguration == .corners(radius: 10))
        #expect(subject.dealStepper.backgroundColor == .clear)
        #expect(subject.dealStepper.layer.borderColor == UIColor.label.cgColor)
        #expect(subject.dealStepper.layer.borderWidth == 1)
        #expect(subject.dealNumberTextField.delegate === subject)
        #expect(subject.dealNumberTextField.keyboardType == .numberPad)
        #expect(subject.dealStepper.actions(forTarget: subject, forControlEvent: .primaryActionTriggered)?.first == "doDealStepper:")
        #expect(subject.dealButton.actions(forTarget: subject, forControlEvent: .primaryActionTriggered)?.first == "doDealButton:")
        #expect(subject.cancelButton.actions(forTarget: subject, forControlEvent: .primaryActionTriggered)?.first == "doCancelButton:")
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.initialData])
        assertSnapshot(
            of: viewController.view,
            as: .image(
                drawHierarchyInKeyWindow: true,
                size: subject.preferredContentSize,
                traits: UITraitCollection(userInterfaceStyle: .light)
            )
        )
    }

    @Test("view appearing causes dimming view to be added to interface and alpha 1; disappearing reverses that")
    func appearing() async {
        let viewController = UIViewController()
        let window = makeWindow(viewController: viewController)
        #expect(subject.dimmingView.alpha == 0)
        #expect(subject.dimmingView.window == nil)
        viewController.present(subject, animated: false)
        await #while(subject.dimmingView.alpha < 1)
        #expect(subject.dimmingView.alpha == 1)
        #expect(subject.dimmingView.window == window)
        viewController.dismiss(animated: false)
        await #while(subject.dimmingView.alpha > 0)
        #expect(subject.dimmingView.alpha == 0)
        await #while(subject.dimmingView.window != nil)
        #expect(subject.dimmingView.window == nil)
    }

    @Test("adaptive presentation style returns .none")
    func adaptivePresentationStyle() {
        let presentationController = UIPresentationController(presentedViewController: UIViewController(), presenting: UIViewController())
        let result = subject.adaptivePresentationStyle(for: presentationController)
        #expect(result == .none)
    }

    @Test("present: sets text field text, stepper value, deal button enablement")
    func present() async {
        subject.loadViewIfNeeded()
        subject.dealButton.isEnabled = false
        let state = MicrosoftState(currentDealNumber: 20, previousDeals: [30])
        await subject.present(state)
        #expect(subject.dealNumberTextField.text == "20")
        #expect(subject.dealStepper.value == 20)
        #expect(subject.dealButton.isEnabled == true)
    }

    @Test("doDealButton: sends .deal")
    func deal() async {
        subject.doDealButton(self)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.deal])
    }

    @Test("doCancelButton: sends .cancel")
    func cancel() async {
        subject.doCancelButton(self)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.cancel])
    }

    @Test("doDealStepper: sends .stepper")
    func stepper() async {
        subject.loadViewIfNeeded()
        subject.dealStepper.value = 42
        subject.doDealStepper(self)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.last == .stepper(42))
    }

    @Test("textFieldDidChangeSelection: if valid number, sends .userTyped")
    func textFieldDidChange() async {
        subject.loadViewIfNeeded()
        let textField = UITextField()
        textField.text = "42"
        subject.textFieldDidChangeSelection(textField)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived.last == .userTyped(42))
    }

    @Test("textFieldDidChangeSelection: if invalid number, sends nothing, disables deal button")
    func textFieldDidChangeBad() async {
        subject.loadViewIfNeeded()
        subject.dealButton.isEnabled = true
        let textField = UITextField()
        textField.text = "21b"
        subject.textFieldDidChangeSelection(textField)
        #expect(subject.dealButton.isEnabled == false)
        try? await Task.sleep(for: .seconds(0.1))
        #expect(processor.thingsReceived.last == .initialData)
    }
}
