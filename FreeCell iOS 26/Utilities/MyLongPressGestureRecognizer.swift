import UIKit
import UIKit.UIGestureRecognizerSubclass

/// Long press gesture recognizer subclass that exposes its target, action, and settable state,
/// for testing.
final class MyLongPressGestureRecognizer: UILongPressGestureRecognizer {
    weak var target: AnyObject?
    var action: Selector?

    override init(target: Any?, action: Selector?) {
        self.target = target as? AnyObject
        self.action = action
        super.init(target: target, action: action)
    }

    var locationForTesting: CGPoint?
    override func location(in view: UIView?) -> CGPoint {
        return locationForTesting ?? super.location(in: view)
    }
}
