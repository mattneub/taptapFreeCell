import Testing
@testable import FreeCell
import UIKit

struct CGRectTest {
    @Test("center: returns center point")
    func center() {
        let subject = CGRect(x: 20, y: 20, width: 100, height: 100)
        #expect(subject.center == CGPoint(x: 70, y: 70))
    }
}
