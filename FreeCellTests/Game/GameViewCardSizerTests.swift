@testable import TTFreeCell
import Testing
import UIKit

struct GameViewCardSizerTests {
    @Test("card size is correct")
    func cardSize() {
        let result = GameViewCardSizer().cardSize(boardWidth: 1000)
        #expect(result == CGSize(width: 117, height: 155))
        // and this makes sense: 117*8 = 936, plus 16 on both ends = 968
        // the remaining space is 32, which will be divided among 7 gaps of about 4.5 pts
    }
}
