@testable import TTFreeCell
import Testing
import Foundation

private struct DebouncerTests {
    @Test("debouncer debounces")
    func debouncer() async {
        var results = [String]()
        class Delegate: DebouncerDelegate {
            var thingToDo: (() -> Void)?
            func debounced() async {
                thingToDo?()
            }
        }
        let delegate = Delegate()
        delegate.thingToDo = { results.append("done") }
        let subject = Debouncer(interval: 0.3, delegate: delegate)
        subject.eventOccurred()
        try? await Task.sleep(for: .seconds(0.1))
        subject.eventOccurred()
        try? await Task.sleep(for: .seconds(0.1))
        subject.eventOccurred()
        try? await Task.sleep(for: .seconds(0.1))
        subject.eventOccurred()
        try? await Task.sleep(for: .seconds(0.1))
        subject.eventOccurred()
        try? await Task.sleep(for: .seconds(0.6))
        #expect(results == ["done"])
    }
}
