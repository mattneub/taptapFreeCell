@testable import FreeCell
import Testing
import UIKit
import WaitWhile

struct CardViewTests {
    @Test("initialize: view is born with category, translates set to false")
    func initialize() {
        let subject = CardView(category: .column)
        #expect(subject.category == .column)
        #expect(subject.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("redraw: if no cards, shows empty layer with opacity 0.5")
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

    @Test("redraw: if freecell with card, shows card layer with opacity 1")
    func redrawFreecell() async throws {
        let subject = CardView(category: .freeCell)
        CardView.baseSize = .init(width: 100, height: 200)
        subject.cards = [.init(rank: .jack, suit: .hearts)]
        subject.redraw()
        await #while(subject.layer.sublayers?.first == nil)
        let layer = try #require(subject.layer.sublayers?.first as? CardLayer)
        #expect(layer.card == .init(rank: .jack, suit: .hearts))
        #expect(layer.frame == CGRect(x: 0, y: 0, width: 100, height: 200))
        #expect(layer.opacity == 1)
    }

    @Test("redraw: if foundation with card, shows card layer with opacity 0.5")
    func redrawFoundation() async throws {
        let subject = CardView(category: .foundation(.hearts))
        CardView.baseSize = .init(width: 100, height: 200)
        subject.cards = [.init(rank: .jack, suit: .hearts)]
        subject.redraw()
        await #while(subject.layer.sublayers?.first == nil)
        let layer = try #require(subject.layer.sublayers?.first as? CardLayer)
        #expect(layer.card == .init(rank: .jack, suit: .hearts))
        #expect(layer.frame == CGRect(x: 0, y: 0, width: 100, height: 200))
        #expect(layer.opacity == 0.5)
    }
}
