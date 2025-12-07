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

    @Test("receive goBack: pops the last off the undo stack and sends .navigate with it, presents")
    func goBack() async {
        subject.state.undoStack = ["manny", "moe", "jack"]
        await subject.receive(.goBack)
        #expect(subject.state.undoStack == ["manny", "moe"])
        #expect(presenter.thingsReceived == [.navigate(to: "jack")])
        #expect(presenter.statesPresented == [subject.state])
    }

    @Test("receive goLeft: sends goLeft effect, empties the undo stack, presents")
    func goLeft() async {
        subject.state.undoStack = ["manny", "moe", "jack"]
        await subject.receive(.goLeft)
        #expect(presenter.thingsReceived == [.goLeft])
        #expect(subject.state.undoStack.isEmpty)
        #expect(presenter.statesPresented == [subject.state])
    }

    @Test("receive goRight: sends goRight effect, empties the undo stack, presents")
    func goRight() async {
        subject.state.undoStack = ["manny", "moe", "jack"]
        await subject.receive(.goRight)
        #expect(presenter.thingsReceived == [.goRight])
        #expect(subject.state.undoStack.isEmpty)
        #expect(presenter.statesPresented == [subject.state])
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

    @Test("receive navigate: if has a second parameter, also appends to undo stack, presents")
    func navigateFrom() async {
        subject.state.undoStack = ["manny", "moe", "jack"]
        await subject.receive(.navigate(to: "howdy", from: "groucho"))
        #expect(presenter.thingsReceived == [.navigate(to: "howdy")])
        #expect(subject.state.undoStack == ["manny", "moe", "jack", "groucho"])
        #expect(presenter.statesPresented == [subject.state])
    }

    @Test("receive showSafari: calls coordinator showSafari")
    func showSafari() async {
        await subject.receive(.showSafari(url: URL(string: "howdy")!))
        #expect(coordinator.methodsCalled == ["showSafari(url:)"])
        #expect(coordinator.url == URL(string: "howdy")!)
    }

    @Test("receive userSwiped: empties the undo stack, presents")
    func userSwiped() async {
        subject.state.undoStack = ["manny", "moe", "jack"]
        await subject.receive(.userSwiped)
        #expect(subject.state.undoStack.isEmpty)
        #expect(presenter.statesPresented == [subject.state])
    }

}
