@testable import TTFreeCell
import Testing
import UIKit
import WaitWhile

private struct LifetimeTests {
    @Test("did activate emits becomeActive")
    func didBecomeActive() async throws {
        let subject = Lifetime()
        var observed = [LifetimeEvent]()
        _ = Task {
            for await event in subject.stream {
                observed.append(event)
            }
        }
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        NotificationCenter.default.post(UIScene.DidActivateMessage(scene: scene))
        await #while(observed.isEmpty)
        #expect(observed == [.becomeActive])
    }

    @Test("will deactivate emits resign active")
    func willResignActive() async throws {
        let subject = Lifetime()
        var observed = [LifetimeEvent]()
        _ = Task {
            for await event in subject.stream {
                observed.append(event)
            }
        }
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        NotificationCenter.default.post(UIScene.WillDeactivateMessage(scene: scene))
        await #while(observed.isEmpty)
        #expect(observed == [.resignActive])
    }

    @Test("didEnterBackground emits enter background")
    func didEnterBackground() async throws {
        let subject = Lifetime()
        var observed = [LifetimeEvent]()
        _ = Task {
            for await event in subject.stream {
                observed.append(event)
            }
        }
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        NotificationCenter.default.post(UIScene.DidEnterBackgroundMessage(scene: scene))
        await #while(observed.isEmpty)
        #expect(observed == [.enterBackground])
    }
}
