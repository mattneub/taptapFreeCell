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
        let result = await subject.viewController(for: stat)
        let savedImage = try Data(contentsOf: subject.previewImageURL) // it has _replaced_ "dummy"
        #expect(savedImage == expectedImage.pngData()!)
        let viewController = try #require(result as? QLPreviewController)
        #expect(viewController.dataSource === subject)
    }
}
