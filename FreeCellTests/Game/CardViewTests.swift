@testable import FreeCell
import Testing
import UIKit

struct CardViewTests {
    @Test("initialize: view is born with category, translates set to false")
    func initialize() {
        let subject = CardView(category: .column)
        #expect(subject.category == .column)
        #expect(subject.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("redraw: if no cards, shows empty layer")
    func redrawNoCards() throws {
        let subject = CardView(category: .column)
        CardView.baseSize = .init(width: 100, height: 200)
        subject.redraw()
        let layer = try #require(subject.emptyLayer)
        #expect(layer.superlayer === subject.layer)
        #expect(layer.frame == CGRect(x: 4, y: 4, width: 92, height: 192))
        #expect(layer.cornerRadius == 4)
        #expect(layer.masksToBounds == true)
        #expect(layer.backgroundColor == UIColor.white.cgColor)
        #expect(layer.zPosition == -1)
        #expect(layer.opacity == 0.5)
    }
}
