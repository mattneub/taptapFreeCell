import UIKit

/// UIAction subclass that provides a reference to its handler, for testing.
final class MyUIAction: UIAction {
    var handler: ((UIAction) -> Void)?

    convenience init(
        myTitle: String = "",
        subtitle: String? = nil,
        image: UIImage? = nil,
        identifier: UIAction.Identifier? = nil,
        discoverabilityTitle: String? = nil,
        attributes: UIMenuElement.Attributes = [],
        state: UIMenuElement.State = .off,
        handler: @escaping UIActionHandler
    ) {
        self.init(
            title: myTitle,
            subtitle: subtitle,
            image: image,
            identifier: identifier,
            discoverabilityTitle: discoverabilityTitle,
            attributes: attributes,
            state: state,
            handler: handler
        )
        self.handler = handler
    }
}
