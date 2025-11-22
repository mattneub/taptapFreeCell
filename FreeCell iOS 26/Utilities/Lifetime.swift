import Observation

protocol LifetimeType {
    var event: LifetimeEvent? { get }

    func didBecomeActive()
    func didEnterBackground()
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
    func didEnterBackground() {
        event = .enterBackground
    }
}

enum LifetimeEvent {
    case becomeActive
    case enterBackground
    case resignActive
}
