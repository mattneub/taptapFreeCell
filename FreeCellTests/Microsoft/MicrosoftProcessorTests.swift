@testable import TTFreeCell
import Testing
import Foundation

private struct MicrosoftProcessorTests {
    let subject = MicrosoftProcessor()
    let presenter = MockReceiverPresenter<Void, MicrosoftState>()
    let persistence = MockPersistence()
    let coordinator = MockRootCoordinator()
    let stats = MockStats()
    let delegate = MockDelegate()

    init() {
        subject.coordinator = coordinator
        subject.presenter = presenter
        subject.delegate = delegate
        services.persistence = persistence
        services.stats = stats
    }

    @Test("receive cancel: calls coordinator dismiss")
    func cancel() async {
        await subject.receive(.cancel)
        #expect(coordinator.methodsCalled == ["dismiss()"])
    }

    @Test("receive deal: saves deal number to persistence, calls coordinator dismiss, calls delegate")
    func deal() async {
        subject.state.currentDealNumber = 42
        await subject.receive(.deal)
        #expect(persistence.methodsCalled == ["saveLastMicrosoftDeal(_:)"])
        #expect(persistence.microsoftDealSet == 42)
        #expect(coordinator.methodsCalled == ["dismiss()"])
        #expect(delegate.methodsCalled == ["dealMicrosoftNumber(_:)"])
        #expect(delegate.dealNumber == 42)
    }

    @Test("receive initialData: configures state from persistence and stats, presents it")
    func initialData() async {
        persistence.microsoftDealToReturn = 30
        var layout1 = Layout()
        layout1.microsoftDealNumber = 10
        var layout2 = Layout()
        layout2.microsoftDealNumber = 20
        let statsDictionary: StatsDictionary = [
            "hey": Stat(dateFinished: Date(timeIntervalSince1970: 2), won: true, initialLayout: layout1, movesCount: 1, timeTaken: 3),
            "ho": Stat(dateFinished: Date(timeIntervalSince1970: 3), won: true, initialLayout: layout2, movesCount: 3, timeTaken: 2),
            "ha": Stat(dateFinished: Date(timeIntervalSince1970: 4), won: false, initialLayout: Layout(), movesCount: 2, timeTaken: 1)
        ]
        stats.stats = statsDictionary
        await subject.receive(.initialData)
        #expect(persistence.methodsCalled == ["loadLastMicrosoftDeal()"])
        #expect(subject.state.currentDealNumber == 30)
        #expect(subject.state.previousDeals == Set([10, 20]))
        #expect(presenter.statesPresented == [subject.state])
    }

    @Test("receive initialData: edge case: if persistence value is 0, state value is 1")
    func initialDataEdgeCase() async {
        persistence.microsoftDealToReturn = 0
        await subject.receive(.initialData)
        #expect(subject.state.currentDealNumber == 1)
    }

    @Test("stepper: sets the current deal number and presents it")
    func stepper() async {
        await subject.receive(.stepper(42))
        #expect(subject.state.currentDealNumber == 42)
        #expect(presenter.statesPresented == [subject.state])
    }

    @Test("userTyped: sets the current deal number and presents it")
    func userTyped() async {
        await subject.receive(.userTyped(42))
        #expect(subject.state.currentDealNumber == 42)
        #expect(presenter.statesPresented == [subject.state])
    }
}

private final class MockDelegate: MicrosoftDelegate {
    var methodsCalled = [String]()
    var dealNumber: Int?
    func dealMicrosoftNumber(_ dealNumber: Int) async {
        methodsCalled.append(#function)
        self.dealNumber = dealNumber
    }
}
