@testable import TTFreeCell
import Testing
import UIKit
import QuickLook

private struct PreviewerTests {
    let subject = Previewer()

    @Test("previewImageURL is correct")
    func previewImageURL() {
        let expected = URL.temporaryDirectory.appendingPathComponent("Deal.png")
        #expect(subject.previewImageURL == expected)
    }

    @Test("viewControllerForStat: saves snapshot, returns QLPreviewController with correct datasource")
    func viewController() async throws {
        try "dummy".write(to: subject.previewImageURL, atomically: true, encoding: .utf8)
        CardView.baseSize = CardImage.sourceImageSize
        var layout = Layout()
        let deck = Deck()
        layout.deal(deck)
        let stat = Stat(dateFinished: Date.distantPast, won: false, initialLayout: layout, movesCount: 0, timeTaken: 0)
        let expectedImage = await UIImage.snapshot(for: stat)
        let source = UIView()
        let result = await subject.viewController(for: stat, source: source)
        #expect(subject.source === source)
        let savedImage = try Data(contentsOf: subject.previewImageURL) // it has _replaced_ "dummy"
        #expect(savedImage == expectedImage.pngData()!)
        let viewController = try #require(result as? QLPreviewController)
        #expect(viewController.dataSource === subject)
        #expect(viewController.delegate === subject)
    }

    @Test("number of preview items is 1")
    func number() {
        let controller = QLPreviewController()
        #expect(subject.numberOfPreviewItems(in: controller) == 1)
    }

    @Test("preview item is preview image url")
    func previewItem() {
        let controller = QLPreviewController()
        #expect(subject.previewController(controller, previewItemAt: 0) as? URL == subject.previewImageURL)
    }

    @Test("transition view is source")
    func transitionView() {
        let controller = QLPreviewController()
        let source = UIView()
        subject.source = source
        #expect(subject.previewController(controller, transitionViewFor: NSURL()) === source)
    }
}
