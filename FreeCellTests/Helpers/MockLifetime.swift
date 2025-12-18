@testable import TTFreeCell
import UIKit

@Observable
final class MockLifetime: LifetimeType {
    var stream: AsyncStream<LifetimeEvent>!

    nonisolated(unsafe) var continuation: AsyncStream<LifetimeEvent>.Continuation?

    init() {
        self.stream = AsyncStream<LifetimeEvent>() { continuation in
            self.continuation = continuation
        }
    }

    deinit {
        self.continuation?.finish()
    }
}
