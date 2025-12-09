@testable import TTFreeCell
import Testing
import UIKit
import WaitWhile
import SnapshotTesting

private struct ExportViewControllerTests {
    let subject = ExportViewController()
    let processor = MockReceiver<ExportAction>()

    init() {
        subject.processor = processor
    }

    @Test("exportLabel is correctly constructed")
    func exportLabel() {
        let label = subject.exportLabel
        #expect(label.translatesAutoresizingMaskIntoConstraints == false)
        #expect(label.font == UIFont.systemFont(ofSize: 17))
        #expect(label.numberOfLines == 0)
    }

    @Test("importLabel is correctly constructed")
    func importLabel() {
        let label = subject.importLabel
        #expect(label.translatesAutoresizingMaskIntoConstraints == false)
        #expect(label.font == UIFont.systemFont(ofSize: 17))
        #expect(label.numberOfLines == 0)
    }

    @Test("cancelButton1 is correctly constructed")
    func cancelButton1() {
        let button = subject.cancelButton1
        // don't know how to test "style" of the configuration, see snapshot test instead
        #expect(button.translatesAutoresizingMaskIntoConstraints == false)
        #expect(button.configuration?.title == "Cancel")
        let result = button.configuration?.titleTextAttributesTransformer?(AttributeContainer())
        #expect(result?.font == UIFont.systemFont(ofSize: 15))
        #expect(button.actions(forTarget: subject, forControlEvent: .primaryActionTriggered)?.first == "doCancel")
    }

    @Test("cancelButton2 is correctly constructed")
    func cancelButton2() {
        let button = subject.cancelButton2
        // don't know how to test "style" of the configuration, see snapshot test instead
        #expect(button.translatesAutoresizingMaskIntoConstraints == false)
        #expect(button.configuration?.title == "Cancel")
        let result = button.configuration?.titleTextAttributesTransformer?(AttributeContainer())
        #expect(result?.font == UIFont.systemFont(ofSize: 15))
        #expect(button.actions(forTarget: subject, forControlEvent: .primaryActionTriggered)?.first == "doCancel")
    }

    @Test("exportButton is correctly constructed")
    func exportButton() {
        let button = subject.exportButton
        // don't know how to test "style" of the configuration, see snapshot test instead
        #expect(button.translatesAutoresizingMaskIntoConstraints == false)
        #expect(button.configuration?.title == "Export")
        let result = button.configuration?.titleTextAttributesTransformer?(AttributeContainer())
        #expect(result?.font == UIFont.systemFont(ofSize: 15))
        #expect(button.actions(forTarget: subject, forControlEvent: .primaryActionTriggered)?.first == "doExport")
    }

    @Test("importButton is correctly constructed")
    func importButton() {
        let button = subject.importButton
        // don't know how to test "style" of the configuration, see snapshot test instead
        #expect(button.translatesAutoresizingMaskIntoConstraints == false)
        #expect(button.configuration?.title == "Import and Deal")
        let result = button.configuration?.titleTextAttributesTransformer?(AttributeContainer())
        #expect(result?.font == UIFont.systemFont(ofSize: 15))
        #expect(button.actions(forTarget: subject, forControlEvent: .primaryActionTriggered)?.first == "doImportAndDeal")
    }

    @Test("textView is correctly constructed")
    func textView() {
        let textView = subject.textView
        #expect(textView.translatesAutoresizingMaskIntoConstraints == false)
        #expect(textView.font == UIFont.systemFont(ofSize: 14))
    }

    @Test("scrollView is correctly constructed")
    func scrollView() {
        let scrollView = subject.scrollView
        #expect(scrollView.translatesAutoresizingMaskIntoConstraints == false)
        #expect(scrollView.showsVerticalScrollIndicator == false)
        #expect(scrollView.showsHorizontalScrollIndicator == false)
        #expect(scrollView.keyboardDismissMode == .interactive)
    }

    @Test("contentView is correctly constructed")
    func contentView() {
        let contentView = subject.contentView
        #expect(contentView.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("viewDidLoad: sets background Color, adds subviews, sends initialData")
    func viewDidLoad() async {
        subject.loadViewIfNeeded()
        #expect(subject.view.backgroundColor == .secondarySystemBackground)
        #expect(subject.cancelButton1.isDescendant(of: subject.view))
        #expect(subject.cancelButton2.isDescendant(of: subject.view))
        #expect(subject.importButton.isDescendant(of: subject.view))
        #expect(subject.exportButton.isDescendant(of: subject.view))
        #expect(subject.textView.isDescendant(of: subject.view))
        #expect(subject.importLabel.isDescendant(of: subject.view))
        #expect(subject.exportLabel.isDescendant(of: subject.view))
        #expect(subject.contentView.isDescendant(of: subject.view))
        #expect(subject.scrollView.isDescendant(of: subject.view))
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.initialData])
    }

    @Test("present: sets label texts")
    func present() async {
        await subject.present(ExportState())
        #expect(subject.importLabel.text == ExportState().importText)
        #expect(subject.exportLabel.text == ExportState().exportText)
    }

    @Test("view looks okay")
    func viewLooksOkay() async {
        let window = makeWindow(view: subject.view)
        await subject.present(ExportState())
        subject.view.widthAnchor.constraint(equalToConstant: 500).activate(priority: 999)
        subject.view.heightAnchor.constraint(equalToConstant: 450).activate(priority: 999)
        window.layoutIfNeeded()
        assertSnapshot(of: subject.view, as: .image())
    }

    @Test("doCancel: sends cancel")
    func doCancel() async {
        subject.doCancel()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.cancel])
    }

    @Test("doImportAndDeal: sends import with text view text")
    func doImport() async {
        subject.textView.text = "howdy"
        subject.doImportAndDeal()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.import("howdy")])
    }

    @Test("doExport: sends export")
    func doExport() async {
        subject.doExport()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.export])
    }
}
