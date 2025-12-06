@testable import TTFreeCell
import Testing
import Foundation
import WaitWhile

private struct HelpProcessorTests {
    let subject = HelpProcessor()
    let presenter = MockReceiverPresenter<HelpEffect, HelpState>()
    let coordinator = MockRootCoordinator()

    init() {
        subject.coordinator = coordinator
        subject.presenter = presenter
    }

    @Test("receive goLeft: sends goLeft effect")
    func goLeft() async {
        await subject.receive(.goLeft)
        #expect(presenter.thingsReceived == [.goLeft])
    }

    @Test("receive goRight: sends goRight effect")
    func goRight() async {
        await subject.receive(.goRight)
        #expect(presenter.thingsReceived == [.goRight])
    }

    @Test("receive initialData: presents state")
    func initialData() async {
        await subject.receive(.initialData)
        #expect(presenter.statesPresented == [subject.state])
    }

    @Test("receive navigate: sends navigate effect")
    func navigate() async {
        await subject.receive(.navigate(to: "howdy"))
        #expect(presenter.thingsReceived == [.navigate(to: "howdy")])
    }

    @Test("receive showSafari: calls coordinator showSafari")
    func showSafari() async {
        await subject.receive(.showSafari(url: URL(string: "howdy")!))
        #expect(coordinator.methodsCalled == ["showSafari(url:)"])
        #expect(coordinator.url == URL(string: "howdy")!)
    }

}
