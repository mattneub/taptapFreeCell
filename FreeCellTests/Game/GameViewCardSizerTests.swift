@testable import TTFreeCell
import Testing
import UIKit

private struct GameViewCardSizerTests {
    @Test("card size is correct")
    func cardSize() {
        let result = GameViewCardSizer().cardSize(boardWidth: 500)
        #expect(result == CGSize(width: 56, height: 74))
        // and this makes sense: 56*8 = 448, plus 16 on both ends = 464
        // the remaining space is 36, which will be divided among 7 gaps of about 5 pts
    }

    @Test("card size is correct for a wide width; in particular 700 or wider is the same")
    func cardSizeWide() {
        var result = GameViewCardSizer().cardSize(boardWidth: 700)
        #expect(result == CGSize(width: 80, height: 106))
        result = GameViewCardSizer().cardSize(boardWidth: 1000)
        #expect(result == CGSize(width: 80, height: 106))
    }
}
