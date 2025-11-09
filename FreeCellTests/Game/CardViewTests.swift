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

    @Test("redraw: if no cards, shows empty layer with opacity 0.5")
    func redrawNoCards() async throws {
        let subject = CardView(category: .column)
        CardView.baseSize = .init(width: 100, height: 200)
        await subject.redraw()
        let layer = try #require(subject.emptyLayer)
        #expect(layer.superlayer === subject.layer)
        #expect(layer.frame == CGRect(x: 4, y: 2, width: 92, height: 192))
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
        await subject.redraw()
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
        await subject.redraw()
        let layer = try #require(subject.layer.sublayers?.first as? CardLayer)
        #expect(layer.card == .init(rank: .jack, suit: .hearts))
        #expect(layer.frame == CGRect(x: 0, y: 0, width: 100, height: 200))
        #expect(layer.opacity == 0.5)
    }

    @Test("redraw: if column with cards, shows card layers")
    func redrawColumn() async throws {
        let subject = CardView(category: .column)
        CardView.baseSize = .init(width: 100, height: 200)
        subject.cards = [
            .init(rank: .jack, suit: .hearts),
            .init(rank: .nine, suit: .spades),
            .init(rank: .eight, suit: .diamonds),
        ]
        await subject.redraw()
        let layers = try #require(subject.layer.sublayers as? [CardLayer])
        #expect(layers[0].card == .init(rank: .jack, suit: .hearts))
        #expect(layers[0].frame == CGRect(x: 0, y: 0, width: 100, height: 200))
        #expect(layers[0].zPosition == 0)
        #expect(layers[1].card == .init(rank: .nine, suit: .spades))
        #expect(layers[1].frame == CGRect(x: 0, y: 100, width: 100, height: 200))
        #expect(layers[1].zPosition == 1)
        #expect(layers[2].card == .init(rank: .eight, suit: .diamonds))
        #expect(layers[2].frame == CGRect(x: 0, y: 200, width: 100, height: 200))
        #expect(layers[2].zPosition == 2)
        #expect(subject.heightConstraint.constant == 400)
    }

    @Test("redraw: column with movableCount draws border layer")
    func redrawColumnMovableCount() async throws {
        let subject = CardView(category: .column)
        CardView.baseSize = .init(width: 100, height: 200)
        subject.cards = [
            .init(rank: .jack, suit: .hearts),
            .init(rank: .nine, suit: .spades),
            .init(rank: .eight, suit: .diamonds),
        ]
        await subject.redraw(movableCount: 2)
        let border = try #require(subject.layer.sublayers?.last)
        #expect(border.borderColor == UIColor.blue.cgColor)
        #expect(border.borderWidth == 2)
        #expect(border.frame == CGRect(x: 0, y: 102, width: 100, height: 296))
        #expect(border.zPosition == 3)
        #expect(border.cornerRadius == 4)
    }
}
