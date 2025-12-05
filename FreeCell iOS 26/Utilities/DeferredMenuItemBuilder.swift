import UIKit

/// Factory class for making an uncached UIDeferredMenuElement. This is so we can mock the
/// deferred menu element; we cannot subclass it so we test by subclassing the factory instead.
class DeferredMenuItemBuilder {
    required init() {}

    func build(_ handler: @escaping (@escaping ([UIAction]) -> Void) -> Void) -> UIDeferredMenuElement {
        UIDeferredMenuElement.uncached(_: handler)
    }
}
