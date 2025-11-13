import UIKit

final class TransactionWaiter {
    static let shared = TransactionWaiter()
    private init() {}
    var continuation: CheckedContinuation<Void, Never>?
    func perform(_ operation: () -> ()) async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.continuation?.resume(returning: ())
                self.continuation = nil
            }
            operation()
            CATransaction.commit()
        }
    }
}
