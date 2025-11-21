import UIKit

/// Extension that provides a `center` property for CGRect.
extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

