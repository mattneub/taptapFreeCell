import UIKit
import Testing
@testable import TTFreeCell
import SnapshotTesting

private struct UIImageTests {
    @Test("snapshot for stat looks right")
    func snapshotForStat() async {
        CardView.baseSize = CardImage.sourceImageSize
        var layout = Layout()
        let deck = Deck()
        layout.deal(deck)
        let stat = Stat(dateFinished: Date.distantPast, won: false, initialLayout: layout, movesCount: 0, timeTaken: 0)
        let result = await UIImage.snapshot(for: stat)
        #expect(result.size == CGSize(width: 300, height: 243))
        assertSnapshot(of: result, as: .image)
    }
}
