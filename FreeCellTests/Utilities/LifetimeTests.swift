@testable import TTFreeCell
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

    @Test("didEnterBackground: publishes from event")
    func didEnterBackground() async {
        let subject = Lifetime()
        let observation = Observations { return subject.event }
        var observed = [LifetimeEvent?]()
        _ = Task {
            for await event in observation {
                observed.append(event)
            }
        }
        subject.didEnterBackground()
        await Task.yield()
        #expect(observed == [.enterBackground])
    }
}
