@testable import TTFreeCell
import Testing
import Foundation

private struct PrefsProcessorTests {
    let subject = PrefsProcessor()
    let presenter = MockReceiverPresenter<PrefsEffect, PrefsState>()
    let coordinator = MockRootCoordinator()
    fileprivate let delegate = MockDelegate()

    init() {
        subject.presenter = presenter
        subject.coordinator = coordinator
        subject.delegate = delegate
    }

    @Test("receive initialData: presents state")
    func initialData() async {
        subject.state = PrefsState(prefs: [Pref(key: .automoveToFoundations, value: true)], speed: .glacial)
        await subject.receive(.initialData)
        #expect(presenter.statesPresented == [subject.state])
    }

    @Test("receive prefChanged: sends prefChanged to delegate and presenter")
    func prefChanged() async {
        await subject.receive(.prefChanged(.automoveToFoundations, value: true))
        #expect(delegate.methodsCalled == ["prefChanged(_:value:)"])
        #expect(delegate.keys == [.automoveToFoundations])
        #expect(delegate.values == [true])
        #expect(presenter.thingsReceived == [.prefChanged(.automoveToFoundations, value: true)])
    }

    @Test("receive prefChanged: if pref has subordinate and is false, sends prefChanged subordinate to false to delegate and presenter")
    func prefChangedHasSubordinate() async {
        await subject.receive(.prefChanged(.automoveToFoundations, value: false))
        #expect(delegate.methodsCalled == ["prefChanged(_:value:)", "prefChanged(_:value:)"])
        #expect(delegate.keys == [.automoveToFoundations, .earlyEndgame])
        #expect(delegate.values == [false, false])
        #expect(presenter.thingsReceived == [
            .prefChanged(.automoveToFoundations, value: false),
            .prefChanged(.earlyEndgame, value: false)
        ])
    }

    @Test("receive prefChanged: if pref has superordinate and is true, sends prefChanged superordinate to true to delegate and presenter")
    func prefChangedHasSuperordinate() async {
        await subject.receive(.prefChanged(.earlyEndgame, value: true))
        #expect(delegate.methodsCalled == ["prefChanged(_:value:)", "prefChanged(_:value:)"])
        #expect(delegate.keys == [.earlyEndgame, .automoveToFoundations])
        #expect(delegate.values == [true, true])
        #expect(presenter.thingsReceived == [
            .prefChanged(.earlyEndgame, value: true),
            .prefChanged(.automoveToFoundations, value: true)
        ])
    }

    @Test("receive speedChanged: sends speedChanged to delegate and presenter")
    func speedChanged() async {
        await subject.receive(.speedChanged(index: 0))
        #expect(delegate.methodsCalled == ["speedChanged(index:)"])
        #expect(delegate.index == 0)
        #expect(presenter.thingsReceived == [.speedChanged(index: 0)])
    }

}

fileprivate final class MockDelegate: PrefsDelegate {
    var methodsCalled = [String]()
    var keys = [PrefKey]()
    var values = [Bool]()
    var index: Int?

    func prefChanged(_ key: PrefKey, value: Bool) async {
        methodsCalled.append(#function)
        self.keys.append(key)
        self.values.append(value)
    }

    func speedChanged(index: Int) async {
        methodsCalled.append(#function)
        self.index = index
    }
}

