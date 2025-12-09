@testable import TTFreeCell
import Testing
import Foundation

private struct ExportProcessorTests {
    let subject = ExportProcessor()
    let presenter = MockReceiverPresenter<Void, ExportState>()
    let coordinator = MockRootCoordinator()
    let delegate = MockExportDelegate()

    init() {
        subject.coordinator = coordinator
        subject.presenter = presenter
        subject.delegate = delegate
    }

    @Test("receive cancel: calls coordinator dismiss")
    func cancel() async {
        await subject.receive(.cancel)
        #expect(coordinator.methodsCalled == ["dismiss()"])
    }

    @Test("receive export: calls coordinator dismiss, calls delegate export")
    func export() async {
        await subject.receive(.export)
        #expect(coordinator.methodsCalled == ["dismiss()"])
        #expect(delegate.methodsCalled == ["exportCurrentGame()"])
    }

    @Test("receive import: calls coordinator dismiss, calls delegate import with text")
    func `import`() async {
        await subject.receive(.import("howdy"))
        #expect(coordinator.methodsCalled == ["dismiss()"])
        #expect(delegate.methodsCalled == ["importGame(_:)"])
        #expect(delegate.text == "howdy")
    }

    @Test("receive initialData: presents state")
    func initialData() async {
        await subject.receive(.initialData)
        #expect(presenter.statesPresented == [subject.state])
    }
}

final class MockExportDelegate: ExportDelegate {
    var methodsCalled = [String]()
    var text: String?

    func exportCurrentGame() {
        methodsCalled.append(#function)
    }

    func importGame(_ text: String?) async {
        methodsCalled.append(#function)
        self.text = text
    }

}

