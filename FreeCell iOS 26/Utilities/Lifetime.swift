import UIKit

protocol LifetimeType {
    var stream: AsyncStream<LifetimeEvent>! { get }
}

final class Lifetime: LifetimeType {
    /// Retain notification observers here.
    var observers: [NotificationCenter.ObservationToken] = []

    /// Public stream, to which anyone can subscribe.
    var stream: AsyncStream<LifetimeEvent>!

    /// Private continuation of the above stream, so we can yield into the stream.
    var continuation: AsyncStream<LifetimeEvent>.Continuation?

    init() {
        // configure notification observers; we yield into our async stream on each event received
        do {
            let observer = NotificationCenter.default.addObserver(of: UIScene.self, for: .didActivate) { [weak self] _ in
                self?.continuation?.yield(.becomeActive)
            }
            observers.append(observer)
        }
        do {
            let observer = NotificationCenter.default.addObserver(of: UIScene.self, for: .didEnterBackground) { [weak self] _ in
                self?.continuation?.yield(.enterBackground)
            }
            observers.append(observer)
        }
        do {
            let observer = NotificationCenter.default.addObserver(of: UIScene.self, for: .willDeactivate) { [weak self] _ in
                self?.continuation?.yield(.resignActive)
            }
            observers.append(observer)
        }
        // and create the stream
        self.stream = AsyncStream<LifetimeEvent> { continuation in
            self.continuation = continuation
        }
    }

    deinit {
        continuation?.finish()
    }
}

enum LifetimeEvent {
    case becomeActive
    case enterBackground
    case resignActive
}
