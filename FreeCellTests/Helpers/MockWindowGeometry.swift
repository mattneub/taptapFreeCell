@testable import TTFreeCell

final class MockWindowGeometry: WindowGeometryType {
    var methodsCalled = [String]()
    var scene: (any HasGeometry)?
    var coordinator: (any RootCoordinatorType)?

    func geometryUpdated(scene: any HasGeometry, coordinator: any RootCoordinatorType) {
        methodsCalled.append(#function)
        self.scene = scene
        self.coordinator = coordinator
    }
}
