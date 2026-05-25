import UIKit

protocol WindowGeometryType {
    func geometryUpdated(scene: any HasGeometry, coordinator: any RootCoordinatorType)
}

/// Service object that knows how to respond to changes in the window geometry.
final class WindowGeometry: WindowGeometryType {
    /// Tracks the most recent scene size, so that we know when it changes.
    var previousSceneSize = CGSize.zero

    /// Public method: decide whether to rip out or restore the interface based on the scene
    /// geometry, and if so, call the appropriate coordinator method.
    func geometryUpdated(scene: any HasGeometry, coordinator: any RootCoordinatorType) {
        let geometry = scene.geometry
        let sceneSize = geometry.size
        // Hide interface during interactive resizing. Unfortunately we get called if the
        // user is interactively resizing a different app's window! So to prevent interface hiding
        // while that is going on, we check the previous scene size.
        if geometry.isInteractivelyResizing && sceneSize != previousSceneSize {
            previousSceneSize = sceneSize
            coordinator.hideInterface()
        }
        // Show interface when geometry-changing ends. There is no way to know whether this is
        // a one-shot change or comes after interactive resizing, so just do it (and no harm done
        // if `updateInterface` hides and rebuilds the interface; the user won't see a flash).
        if !geometry.isInteractivelyResizing {
            let prev = previousSceneSize
            previousSceneSize = sceneSize
            if prev != .zero {
                coordinator.updateInterface()
            }
        }
    }

}

// Protocols and extensions that allow us to substitute mocks in the call to `geometryUpdated`,
// for testing.

protocol HasGeometry: AnyObject {
    var geometry: any GeometryType { get }
}
extension UIWindowScene: HasGeometry {
    var geometry: any GeometryType { effectiveGeometry }
}

protocol GeometryType: AnyObject {
    var size: CGSize { get }
    var isInteractivelyResizing: Bool { get }
}
extension UIWindowScene.Geometry: GeometryType {
    var size: CGSize { coordinateSpace.bounds.size }
}

