import Testing
@testable import FreeCell
import UIKit

struct CALayerTests {
    @Test("sublayers(ofType:) returns array of type, recursing")
    func sublayersOfType() {
        let subject = CALayer()
        let sub1 = BorderLayer()
        subject.addSublayer(sub1)
        let sub2 = CALayer()
        subject.addSublayer(sub2)
        let sub11 = BorderLayer()
        sub1.addSublayer(sub11)
        let sub21 = CALayer()
        sub2.addSublayer(sub21)
        let sub22 = BorderLayer()
        sub2.addSublayer(sub22)
        #expect(subject.sublayers(ofType: BorderLayer.self) == [sub1, sub11, sub22])
    }
}

