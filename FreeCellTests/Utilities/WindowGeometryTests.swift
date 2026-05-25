@testable import TTFreeCell
import Testing
import UIKit

private struct WindowGeometryTests {
    let subject = WindowGeometry()
    let coordinator = MockRootCoordinator()
    let scene = MockHasGeometry()

    @Test("geometryUpdated: if resizing, size changed, updates size, calls coordinator hideInterface")
    func geometryUpdatedInteractivelyResizing() {
        (scene.geometry as? MockIsGeometry)?.isInteractivelyResizing = true
        (scene.geometry as? MockIsGeometry)?.size = .init(width: 20, height: 20)
        subject.previousSceneSize = .init(width: 10, height: 10)
        subject.geometryUpdated(scene: scene, coordinator: coordinator)
        #expect(subject.previousSceneSize == .init(width: 20, height: 20))
        #expect(coordinator.methodsCalled == ["hideInterface()"])
    }

    @Test("geometryUpdated: if resizing, size unchanged, does nothing")
    func geometryUpdatedInteractivelyResizingSizeUnchanged() {
        (scene.geometry as? MockIsGeometry)?.isInteractivelyResizing = true
        (scene.geometry as? MockIsGeometry)?.size = .init(width: 10, height: 10)
        subject.previousSceneSize = .init(width: 10, height: 10)
        subject.geometryUpdated(scene: scene, coordinator: coordinator)
        #expect(subject.previousSceneSize == .init(width: 10, height: 10))
        #expect(coordinator.methodsCalled.isEmpty)
    }

    @Test("geometryUpdated: if not resizing, old size zero, updates size, does nothing else")
    func geometryUpdatedSizeUnchanged() {
        (scene.geometry as? MockIsGeometry)?.isInteractivelyResizing = false
        (scene.geometry as? MockIsGeometry)?.size = .init(width: 10, height: 10)
        subject.previousSceneSize = .zero
        subject.geometryUpdated(scene: scene, coordinator: coordinator)
        #expect(subject.previousSceneSize == .init(width: 10, height: 10))
        #expect(coordinator.methodsCalled.isEmpty)
    }

    @Test("geometryUpdated: if not resizing, old size not zero, updates size, calls coordinator updateInterface")
    func geometryUpdatedSizeChanged() {
        (scene.geometry as? MockIsGeometry)?.isInteractivelyResizing = false
        (scene.geometry as? MockIsGeometry)?.size = .init(width: 20, height: 20)
        subject.previousSceneSize = .init(width: 10, height: 10)
        subject.geometryUpdated(scene: scene, coordinator: coordinator)
        #expect(subject.previousSceneSize == .init(width: 20, height: 20))
        #expect(coordinator.methodsCalled == ["updateInterface()"])
    }
}

final class MockHasGeometry: HasGeometry {
    var geometry: any GeometryType = MockIsGeometry()
}

final class MockIsGeometry: GeometryType {
    var size: CGSize = .zero
    var isInteractivelyResizing: Bool = true
}
