@testable import TTFreeCell
import UIKit

/// Using this object as a vacuum cleaner, and by substituting it for the
/// DeferredMenuItemBuilder object, we can reach right into the app's attempt
/// to construct a UIDeferredMenuElement and extract the UIAction that it passed into the
/// provider function — because the provider function belongs to us! Bwa-ha-ha-ha!
final class MockDeferredMenuItemBuilder: DeferredMenuItemBuilder {
    var handler: ((@escaping ([UIAction]) -> Void) -> Void)?
    var methodsCalled = [String]()

    override func build(_ handler: @escaping (@escaping ([UIAction]) -> Void) -> Void) -> UIDeferredMenuElement {
        methodsCalled.append(#function)
        self.handler = handler
        // that is all we came to do, but we have to return something, so just return something
        return UIDeferredMenuElement.uncached { handler in
            handler([UIAction(title: "dummy", handler: { _ in })])
        }
    }

    /// This is why we are here — to fetch out the action(s) passed into provider function by the app.
    func extractActions() -> [UIAction] {
        var result = [UIAction]()
        func innerHandler(_ actions: [UIAction]) {
            result = actions
        }
        handler?(innerHandler)
        return result
    }
}
