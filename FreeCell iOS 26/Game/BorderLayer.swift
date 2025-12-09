import UIKit

/// A BorderLayer is a simple layer that draws the blue border indicating a sequence at the
/// bottom of a column. It has the remarkable property that it is not susceptible of hit-testing,
/// thus allowing us to use hit-testing to find the "card" the user is long-pressing.
nonisolated
final class BorderLayer: CALayer {
    override init() {
        super.init()
        borderColor = UIColor.blue.cgColor
        borderWidth = 2
        cornerRadius = 4
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_: CGPoint) -> CALayer? {
        return nil
    }
}
