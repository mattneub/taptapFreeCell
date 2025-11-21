import Observation

protocol LifetimeType {
    var event: LifetimeEvent? { get }

    func didBecomeActive()
    func willResignActive()
}

@Observable
final class Lifetime: LifetimeType {
    var event: LifetimeEvent?

    func didBecomeActive() {
        event = .becomeActive
    }
    func willResignActive() {
        event = .resignActive
    }
}

enum LifetimeEvent {
    case becomeActive
    case resignActive
}
