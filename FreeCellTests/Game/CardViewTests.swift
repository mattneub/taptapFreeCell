@testable import FreeCell
import Testing
import UIKit
import WaitWhile

struct CardViewTests {
    @Test("initialize: view is born with location, translates set to false, tapper")
    func initialize() throws {
        let subject = CardView(location: .init(category: .column, index: 0))
        #expect(subject.location.category == .column)
        #expect(subject.location.index == 0)
        #expect(subject.translatesAutoresizingMaskIntoConstraints == false)
        let tapper = try #require(subject.gestureRecognizers?.first as? MyTapGestureRecognizer)
        #expect(tapper.target === subject)
        #expect(tapper.action == #selector(subject.tapped))
    }

    @Test("redraw: if no cards, shows empty layer and has alpha 0.5")
    func redrawNoCards() async throws {
        let subject = CardView(location: .init(category: .column, index: 0))
        CardView.baseSize = .init(width: 100, height: 200)
        await subject.redraw()
        let layer = try #require(subject.layer.sublayers?.first)
        #expect(layer.frame == CGRect(x: 4, y: 2, width: 92, height: 192))
        #expect(layer.cornerRadius == 4)
        #expect(layer.masksToBounds == true)
        #expect(layer.backgroundColor == UIColor.white.cgColor)
        #expect(layer.zPosition == -1)
        #expect(subject.alpha == 0.5)
    }

    @Test("redraw: if no cards, shows empty layer and has alpha 0.5, slightly different frame if not column")
    func redrawNoCardsFreeCell() async throws {
        do {
            let subject = CardView(location: .init(category: .freeCell, index: 0))
            CardView.baseSize = .init(width: 100, height: 200)
            await subject.redraw()
            let layer = try #require(subject.layer.sublayers?.first)
            #expect(layer.frame == CGRect(x: 4, y: 4, width: 92, height: 192))
            #expect(layer.cornerRadius == 4)
            #expect(layer.masksToBounds == true)
            #expect(layer.backgroundColor == UIColor.white.cgColor)
            #expect(layer.zPosition == -1)
            #expect(subject.alpha == 0.5)
        }
        do {
            let subject = CardView(location: .init(category: .foundation, index: 0))
            CardView.baseSize = .init(width: 100, height: 200)
            await subject.redraw()
            let layer = try #require(subject.layer.sublayers?.first)
            #expect(layer.superlayer === subject.layer)
            #expect(layer.frame == CGRect(x: 4, y: 4, width: 92, height: 192))
            #expect(layer.cornerRadius == 4)
            #expect(layer.masksToBounds == true)
            #expect(layer.backgroundColor == UIColor.white.cgColor)
            #expect(layer.zPosition == -1)
            #expect(subject.alpha == 0.5)
        }
    }

    @Test("redraw: if freecell with card, shows card layer and has alpha 1")
    func redrawFreecell() async throws {
        let subject = CardView(location: .init(category: .freeCell, index: 0))
        CardView.baseSize = .init(width: 100, height: 200)
        subject.cards = [.init(rank: .jack, suit: .hearts)]
        await subject.redraw()
        let layer = try #require(subject.layer.sublayers?.first as? CardLayer)
        #expect(layer.card == .init(rank: .jack, suit: .hearts))
        #expect(layer.frame == CGRect(x: 0, y: 0, width: 100, height: 200))
        #expect(subject.alpha == 1)
    }

    @Test("redraw: if foundation with card, shows card layer and has alpha 0.4")
    func redrawFoundation() async throws {
        let subject = CardView(location: .init(category: .foundation, index: 0))
        CardView.baseSize = .init(width: 100, height: 200)
        subject.cards = [.init(rank: .jack, suit: .hearts)]
        await subject.redraw()
        let layer = try #require(subject.layer.sublayers?.first as? CardLayer)
        #expect(layer.card == .init(rank: .jack, suit: .hearts))
        #expect(layer.frame == CGRect(x: 0, y: 0, width: 100, height: 200))
        #expect(subject.alpha == 0.5)
    }

    @Test("redraw: if column with cards, shows card layers")
    func redrawColumn() async throws {
        let subject = CardView(location: .init(category: .column, index: 0))
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
        let subject = CardView(location: .init(category: .column, index: 0))
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
        #expect(border.frame == CGRect(x: 0, y: 101, width: 100, height: 298))
        #expect(border.zPosition == 3)
        #expect(border.cornerRadius == 4)
    }

    @Test("setEnablement: sets alpha as expected")
    func enablement() {
        do {
            let subject = CardView(location: .init(category: .foundation, index: 0))
            subject.setEnablement(.disabled)
            #expect(subject.alpha == 0.5)
            subject.setEnablement(.enabled)
            #expect(subject.alpha == 1)
            subject.setEnablement(.normal)
            #expect(subject.alpha == 0.5)
        }
        do {
            let subject = CardView(location: .init(category: .foundation, index: 0))
            subject.cards = [.init(rank: .queen, suit: .hearts)]
            subject.setEnablement(.disabled)
            #expect(subject.alpha == 0.5)
            subject.setEnablement(.enabled)
            #expect(subject.alpha == 1)
            subject.setEnablement(.normal)
            #expect(subject.alpha == 0.5)
        }
        do {
            let subject = CardView(location: .init(category: .freeCell, index: 0))
            subject.setEnablement(.disabled)
            #expect(subject.alpha == 0.5)
            subject.setEnablement(.enabled)
            #expect(subject.alpha == 1)
            subject.setEnablement(.normal)
            #expect(subject.alpha == 0.5)
        }
        do {
            let subject = CardView(location: .init(category: .freeCell, index: 0))
            subject.cards = [.init(rank: .queen, suit: .hearts)]
            subject.setEnablement(.disabled)
            #expect(subject.alpha == 0.5)
            subject.setEnablement(.enabled)
            #expect(subject.alpha == 1)
            subject.setEnablement(.normal)
            #expect(subject.alpha == 1)
        }
        do {
            let subject = CardView(location: .init(category: .column, index: 0))
            subject.setEnablement(.disabled)
            #expect(subject.alpha == 0.5)
            subject.setEnablement(.enabled)
            #expect(subject.alpha == 1)
            subject.setEnablement(.normal)
            #expect(subject.alpha == 0.5)
        }
        do {
            let subject = CardView(location: .init(category: .column, index: 0))
            subject.cards = [.init(rank: .queen, suit: .hearts)]
            subject.setEnablement(.disabled)
            #expect(subject.alpha == 0.5)
            subject.setEnablement(.enabled)
            #expect(subject.alpha == 1)
            subject.setEnablement(.normal)
            #expect(subject.alpha == 1)
        }
    }

    @Test("tapped: sends tapped to processor")
    func tapped() async {
        let processor = MockReceiver<GameAction>()
        let subject = CardView(location: .init(category: .column, index: 0))
        subject.processor = processor
        subject.tapped()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.tapped(.init(category: .column, index: 0))])
    }
}
