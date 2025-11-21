@testable import FreeCell
import Testing
import Observation

struct LifetimeTests {
    @Test("didBecomeActive: publishes from event")
    func didBecomeActive() async {
        let subject = Lifetime()
        let observation = Observations { return subject.event }
        var observed = [LifetimeEvent?]()
        _ = Task {
            for await event in observation {
                observed.append(event)
            }
        }
        subject.didBecomeActive()
        await Task.yield()
        #expect(observed == [.becomeActive])
    }

    @Test("willResignActive: publishes from event")
    func willResignActive() async {
        let subject = Lifetime()
        let observation = Observations { return subject.event }
        var observed = [LifetimeEvent?]()
        _ = Task {
            for await event in observation {
                observed.append(event)
            }
        }
        subject.willResignActive()
        await Task.yield()
        #expect(observed == [.resignActive])
    }
}
