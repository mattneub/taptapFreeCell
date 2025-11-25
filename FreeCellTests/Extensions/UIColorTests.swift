import UIKit
import Testing
@testable import TTFreeCell

struct UIColorTests {
    @Test("highlightColor is right")
    func highlightColor() {
        #expect(UIColor.highlightColor == UIColor(red: 1, green: 0.836, blue: 0.474, alpha: 0.41))
    }
}
