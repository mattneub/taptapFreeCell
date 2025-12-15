import Foundation
import Observation
import AsyncAlgorithms

protocol DebouncerType {
    init(interval: TimeInterval, delegate: (any DebouncerDelegate)?)
    func eventOccurred()
}

/// Class that debounces. I could have made this a generic, but we only use it in one place
/// so it was simplest to assume there is no information to pass around (i.e. the type is Void).
@Observable final class Debouncer: DebouncerType {
    private var event: Bool = false // meaningless value; the key thing is that we toggle it to signal
    private weak var delegate: (any DebouncerDelegate)?

    init(interval: TimeInterval, delegate: (any DebouncerDelegate)?) {
        self.delegate = delegate
        Task {
            await listenForEvent(interval: interval)
        }
    }

    func eventOccurred() {
        event.toggle()
    }

    private func listenForEvent(interval: TimeInterval) async {
        let observations = Observations { [weak self] in
            return self?.event
        }
        for await _ in observations.debounce(for: .seconds(interval)) {
            await delegate?.debounced()
        }
    }
}

protocol DebouncerDelegate: AnyObject {
    func debounced() async
}
