import UIKit

protocol WindowGeometryType {
    func geometryUpdated(scene: any HasGeometry, coordinator: any RootCoordinatorType)
}

/// Service object that knows how to respond to changes in the window geometry.
final class WindowGeometry: WindowGeometryType {
    /// Tracks the most recent scene size, so that we know when it changes.
    var previousSceneSize = CGSize.zero

    /// Basically copied from
    /// https://developer.apple.com/documentation/technotes/tn3192-Migrating-your-app-from-the-deprecated-UIRequiresFullScreen-key
    /// This is the "right way" to muster a signal that we need to revise layout because
    /// the user, by rotation or dragging, has resized our app window.
    func geometryUpdated(scene: any HasGeometry, coordinator: any RootCoordinatorType) {
        let geometry = scene.geometry
        let sceneSize = geometry.size
        if geometry.isInteractivelyResizing {
            coordinator.hideInterface()
        }
        if !geometry.isInteractivelyResizing && sceneSize != previousSceneSize {
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

