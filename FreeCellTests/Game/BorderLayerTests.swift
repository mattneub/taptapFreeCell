@testable import TTFreeCell
import Testing
import UIKit

struct BorderLayerTests {
    @Test("initialize: sets up the border layer correctly")
    func initialize() {
        let subject = BorderLayer()
        #expect(subject.borderColor == UIColor.blue.cgColor)
        #expect(subject.borderWidth == 2)
        #expect(subject.cornerRadius == 4)
    }

    @Test("hitTest returns nil")
    func hitTest() {
        // first let's prove how this _normally_ works
        let dummy = CALayer()
        dummy.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let dummyResult = dummy.hitTest(CGPoint(x: 50, y: 50))
        #expect(dummyResult === dummy)
        // okay, this is the test
        let subject = BorderLayer()
        subject.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let result = subject.hitTest(CGPoint(x: 50, y: 50))
        #expect(result == nil)
    }
}
