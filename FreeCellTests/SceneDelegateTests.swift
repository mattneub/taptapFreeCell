@testable import TTFreeCell
import Testing
import UIKit

@MainActor
private struct SceneDelegateTests {
    @Test("bootstrap: registers defaults, tells the root coordinator to create the interface")
    func bootstrap() async throws {
        let persistence = MockPersistence()
        services.persistence = persistence
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let subject = SceneDelegate()
        let mockRootCoordinator = MockRootCoordinator()
        subject.coordinator = mockRootCoordinator
        subject.bootstrap(scene: scene)
        #expect(persistence.methodsCalled == ["registerDefaults()"])
        let window = try #require(subject.window)
        #expect(window.isKeyWindow)
        #expect(mockRootCoordinator.methodsCalled == ["createInterface(window:)"])
        #expect(mockRootCoordinator.window === window)
    }
}

