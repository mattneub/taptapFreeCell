import UIKit

extension CALayer {
    /// Return all sublayers of `self`, and of _their_ sublayers, etc.,
    /// that can be cast to the given type.
    /// - Parameter whatType: The type.
    /// - Returns: An array of the given type.
    func sublayers<T: CALayer>(
        ofType whatType: T.Type
    ) -> [T] {
        let layers = sublayers ?? []
        var result: [T] = layers.compactMap { $0 as? T }
        for layer in layers {
            result.append(contentsOf: layer.sublayers(ofType: whatType))
        }
        return result
    }
}
