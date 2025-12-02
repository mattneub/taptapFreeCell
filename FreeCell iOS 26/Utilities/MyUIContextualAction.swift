import UIKit

/// UIContextualAction subclass that exposes the handler, so we can call it during testing.
final class MyUIContextualAction: UIContextualAction {
    var myHandler: UIContextualAction.Handler?
    convenience init(
        myStyle: UIContextualAction.Style,
        title: String?,
        handler: @escaping UIContextualAction.Handler
    ) {
        self.init(style: myStyle, title: title, handler: handler)
        self.myHandler = handler
    }
}
