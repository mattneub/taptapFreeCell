import UIKit

final class MicrosoftViewController: UIViewController, ReceiverPresenter {
    weak var processor: (any Receiver<MicrosoftAction>)?

    @IBOutlet weak var dealNumberTextField: UITextField!
    @IBOutlet weak var dealStepper: UIStepper!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var dealButton : UIButton!
    @IBOutlet weak var cancelButton : UIButton!

    override var preferredContentSize: CGSize {
        get {
            CGSize(width: 250, height: 220)
        }
        set {
            super.preferredContentSize = newValue
        }
    }

    /// Dimming view that will occupy the screen behind us when we are presented as popover.
    lazy var dimmingView = UIView().applying {
        $0.backgroundColor = .black.withAlphaComponent(0.2)
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        $0.alpha = 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        contentView.backgroundColor = .tertiarySystemBackground
        dealStepper.cornerConfiguration = .corners(radius: 10)
        dealStepper.backgroundColor = .clear
        dealStepper.layer.borderColor = UIColor.label.cgColor
        dealStepper.layer.borderWidth = 1
        // I deliberately removed actions from xib, as I don't like hidden magic; let's be explicit
        dealNumberTextField.delegate = self
        dealNumberTextField.keyboardType = .numberPad
        dealStepper.addTarget(self, action: #selector(doDealStepper), for: .primaryActionTriggered)
        dealButton.addTarget(self, action: #selector(doDealButton), for: .primaryActionTriggered)
        cancelButton.addTarget(self, action: #selector(doCancelButton), for: .primaryActionTriggered)
        Task {
            await processor?.receive(.initialData)
        }
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        if let coordinator = transitionCoordinator {
            let container = coordinator.containerView
            dimmingView.frame = container.bounds
            container.addSubview(dimmingView)
            container.sendSubviewToBack(dimmingView)
            coordinator.animate { _ in
                self.dimmingView.alpha = 1
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        transitionCoordinator?.animate { _ in
            self.dimmingView.alpha = 0
        }
    }

    func present(_ state: MicrosoftState) async {
        dealNumberTextField.text = String(state.currentDealNumber)
        dealStepper.value = Double(state.currentDealNumber)
        dealButton.isEnabled = state.dealButtonEnabled
    }

    @IBAction func doDealButton(_ sender: Any) {
        print("doDealButton")
        Task {
            await processor?.receive(.deal)
        }
    }

    @IBAction func doCancelButton(_ sender: Any) {
        Task {
            await processor?.receive(.cancel)
        }
    }

    @IBAction func doDealStepper(_ sender: Any) {
        Task {
            await processor?.receive(.stepper(dealStepper.value))
        }
    }
}

extension MicrosoftViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        // is this a legal game number, and does it exist in stats?
        if let num = Int(textField.text ?? "0") {
            if (1...1_000_000).contains(num) {
                Task {
                    await processor?.receive(.userTyped(num))
                }
                return
            }
        }
        // if we get here, this is not a legal integer; don't even tell the processor,
        // just disable the deal button directly and wait
        self.dealButton.isEnabled = false
    }

    // TODO: Nothing else needed on iPhone, but let's see on iPad
}

/// We are the delegate of our own adaptive presentation (set by coordinator).
extension MicrosoftViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none // be a popover
    }
}
