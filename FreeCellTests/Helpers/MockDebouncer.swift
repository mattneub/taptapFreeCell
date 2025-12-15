@testable import TTFreeCell
import Foundation

final class MockDebouncer: DebouncerType {
    var methodsCalled = [String]()

    init(interval: TimeInterval, delegate: (any DebouncerDelegate)?) {}

    func eventOccurred() {
        methodsCalled.append(#function)
    }

}
