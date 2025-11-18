@testable import FreeCell
import Testing
import UIKit
import WaitWhile

struct CardViewTests {
    @Test("initialize: view is born with location, translates set to false, tapper, long presser")
    func initialize() throws {
        let subject = CardView(location: Location(category: .column, index: 0))
        #expect(subject.location.category == .column)
        #expect(subject.location.index == 0)
        #expect(subject.translatesAutoresizingMaskIntoConstraints == false)
        let tapper = try #require(subject.gestureRecognizers?.first as? MyTapGestureRecognizer)
        #expect(tapper.target === subject)
        #expect(tapper.action == #selector(subject.tapped))
        let longPresser = try #require(subject.gestureRecognizers?.last as? MyLongPressGestureRecognizer)
        #expect(longPresser.minimumPressDuration == 0.25)
        #expect(longPresser.target === subject)
        #expect(longPresser.action == #selector(subject.longPressed))
    }

    @Test("redraw: if no cards, shows empty layer and has alpha 0.5")
    func redrawNoCards() async throws {
        let subject = CardView(location: Location(category: .column, index: 0))
        CardView.baseSize = CGSize(width: 100, height: 200)
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
            let subject = CardView(location: Location(category: .freeCell, index: 0))
            CardView.baseSize = CGSize(width: 100, height: 200)
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
            let subject = CardView(location: Location(category: .foundation, index: 0))
            CardView.baseSize = CGSize(width: 100, height: 200)
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
        let subject = CardView(location: Location(category: .freeCell, index: 0))
        CardView.baseSize = CGSize(width: 100, height: 200)
        subject.cards = [Card(rank: .jack, suit: .hearts)]
        await subject.redraw()
        let layer = try #require(subject.layer.sublayers?.first as? CardLayer)
        #expect(layer.card == Card(rank: .jack, suit: .hearts))
        #expect(layer.frame == CGRect(x: 0, y: 0, width: 100, height: 200))
        #expect(subject.alpha == 1)
    }

    @Test("redraw: if foundation with card, shows card layer and has alpha 0.4")
    func redrawFoundation() async throws {
        let subject = CardView(location: Location(category: .foundation, index: 0))
        CardView.baseSize = CGSize(width: 100, height: 200)
        subject.cards = [Card(rank: .jack, suit: .hearts)]
        await subject.redraw()
        let layer = try #require(subject.layer.sublayers?.first as? CardLayer)
        #expect(layer.card == Card(rank: .jack, suit: .hearts))
        #expect(layer.frame == CGRect(x: 0, y: 0, width: 100, height: 200))
        #expect(subject.alpha == 0.5)
    }

    @Test("redraw: if column with cards, shows card layers")
    func redrawColumn() async throws {
        let subject = CardView(location: Location(category: .column, index: 0))
        CardView.baseSize = CGSize(width: 100, height: 200)
        subject.cards = [
            Card(rank: .jack, suit: .hearts),
            Card(rank: .nine, suit: .spades),
            Card(rank: .eight, suit: .diamonds),
        ]
        await subject.redraw()
        let layers = try #require(subject.layer.sublayers as? [CardLayer])
        #expect(layers[0].card == Card(rank: .jack, suit: .hearts))
        #expect(layers[0].frame == CGRect(x: 0, y: 0, width: 100, height: 200))
        #expect(layers[0].zPosition == 0)
        #expect(layers[1].card == Card(rank: .nine, suit: .spades))
        #expect(layers[1].frame == CGRect(x: 0, y: 100, width: 100, height: 200))
        #expect(layers[1].zPosition == 1)
        #expect(layers[2].card == Card(rank: .eight, suit: .diamonds))
        #expect(layers[2].frame == CGRect(x: 0, y: 200, width: 100, height: 200))
        #expect(layers[2].zPosition == 2)
        #expect(subject.heightConstraint.constant == 400)
    }

    @Test("redraw: column with movableCount draws border layer")
    func redrawColumnMovableCount() async throws {
        let subject = CardView(location: Location(category: .column, index: 0))
        CardView.baseSize = CGSize(width: 100, height: 200)
        subject.cards = [
            Card(rank: .jack, suit: .hearts),
            Card(rank: .nine, suit: .spades),
            Card(rank: .eight, suit: .diamonds),
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
            let subject = CardView(location: Location(category: .foundation, index: 0))
            subject.setEnablement(.disabled)
            #expect(subject.alpha == 0.5)
            subject.setEnablement(.enabled)
            #expect(subject.alpha == 1)
            subject.setEnablement(.normal)
            #expect(subject.alpha == 0.5)
        }
        do {
            let subject = CardView(location: Location(category: .foundation, index: 0))
            subject.cards = [Card(rank: .queen, suit: .hearts)]
            subject.setEnablement(.disabled)
            #expect(subject.alpha == 0.5)
            subject.setEnablement(.enabled)
            #expect(subject.alpha == 1)
            subject.setEnablement(.normal)
            #expect(subject.alpha == 0.5)
        }
        do {
            let subject = CardView(location: Location(category: .freeCell, index: 0))
            subject.setEnablement(.disabled)
            #expect(subject.alpha == 0.5)
            subject.setEnablement(.enabled)
            #expect(subject.alpha == 1)
            subject.setEnablement(.normal)
            #expect(subject.alpha == 0.5)
        }
        do {
            let subject = CardView(location: Location(category: .freeCell, index: 0))
            subject.cards = [Card(rank: .queen, suit: .hearts)]
            subject.setEnablement(.disabled)
            #expect(subject.alpha == 0.5)
            subject.setEnablement(.enabled)
            #expect(subject.alpha == 1)
            subject.setEnablement(.normal)
            #expect(subject.alpha == 1)
        }
        do {
            let subject = CardView(location: Location(category: .column, index: 0))
            subject.setEnablement(.disabled)
            #expect(subject.alpha == 0.5)
            subject.setEnablement(.enabled)
            #expect(subject.alpha == 1)
            subject.setEnablement(.normal)
            #expect(subject.alpha == 0.5)
        }
        do {
            let subject = CardView(location: Location(category: .column, index: 0))
            subject.cards = [Card(rank: .queen, suit: .hearts)]
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
        let subject = CardView(location: Location(category: .column, index: 0))
        subject.processor = processor
        subject.tapped()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.tapped(Location(category: .column, index: 0))])
    }

    @Test("longPressed: if no cards, does nothing")
    func longPressedNoCard() async throws {
        let processor = MockReceiver<GameAction>()
        let subject = CardView(location: Location(category: .foundation, index: 1))
        subject.processor = processor
        let presser = try #require(subject.gestureRecognizers?.last as? MyLongPressGestureRecognizer)
        presser.state = .began // this calls `action` on `target` for us
        try? await Task.sleep(for: .seconds(0.1))
        #expect(processor.thingsReceived.isEmpty)
    }

    @Test("longPressed: if state is `.began`, if foundation or free cell, sends longPress with index -1")
    func longPressedBeganFoundationFreeCell() async throws {
        let processor = MockReceiver<GameAction>()
        let subject = CardView(location: Location(category: .foundation, index: 1))
        subject.cards = [Card(rank: .ace, suit: .clubs)]
        subject.processor = processor
        let presser = try #require(subject.gestureRecognizers?.last as? MyLongPressGestureRecognizer)
        presser.state = .began // this calls `action` on `target` for us
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.longPress(Location(category: .foundation, index: 1), -1)])
    }

    @Test("longPressed: if state is `.began`, if column, sends longPress with z position of hit card layer")
    func longPressedBeganColumn() async throws {
        let processor = MockReceiver<GameAction>()
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let subject = CardView(location: Location(category: .column, index: 1))
        view.addSubview(subject)
        subject.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let cardLayer = await CardLayer(card: Card(rank: .queen, suit: .hearts))
        cardLayer.frame = CGRect(x: 50, y: 50, width: 50, height: 50)
        cardLayer.zPosition = 6
        subject.layer.addSublayer(cardLayer)
        let frontLayer = CALayer()
        frontLayer.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        cardLayer.addSublayer(frontLayer)
        subject.cards = [Card(rank: .ace, suit: .clubs)]
        subject.processor = processor
        let presser = try #require(subject.gestureRecognizers?.last as? MyLongPressGestureRecognizer)
        presser.locationForTesting = CGPoint(x: 75, y: 75)
        // that was all prep! this is the test
        presser.state = .began // this calls `action` on `target` for us
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.longPress(Location(category: .column, index: 1), 6)])
    }

    @Test("longPressed: if state is `.ended`, if foundation or free cell, sends longPressEnded")
    func longPressedEndedFoundationFreeCell() async throws {
        let processor = MockReceiver<GameAction>()
        let subject = CardView(location: Location(category: .foundation, index: 1))
        subject.cards = [Card(rank: .ace, suit: .clubs)]
        subject.processor = processor
        let presser = try #require(subject.gestureRecognizers?.last as? MyLongPressGestureRecognizer)
        presser.state = .ended // this calls `action` on `target` for us
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.longPressEnded])
    }

    @Test("longPressed: if state is `.began`, if column, sends longPress with z position of hit card layer")
    func longPressedEndedColumn() async throws {
        let processor = MockReceiver<GameAction>()
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let subject = CardView(location: Location(category: .column, index: 1))
        view.addSubview(subject)
        subject.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let cardLayer = await CardLayer(card: Card(rank: .queen, suit: .hearts))
        cardLayer.frame = CGRect(x: 50, y: 50, width: 50, height: 50)
        cardLayer.zPosition = 6
        subject.layer.addSublayer(cardLayer)
        let frontLayer = CALayer()
        frontLayer.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        cardLayer.addSublayer(frontLayer)
        subject.cards = [Card(rank: .ace, suit: .clubs)]
        subject.processor = processor
        let presser = try #require(subject.gestureRecognizers?.last as? MyLongPressGestureRecognizer)
        presser.locationForTesting = CGPoint(x: 75, y: 75)
        // that was all prep! this is the test
        presser.state = .ended // this calls `action` on `target` for us
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.longPressEnded])
    }

    @Test("tintCard: puts tint layer in front of card layer at given index")
    func tintCard() async throws {
        let subject = CardView(location: Location(category: .column, index: 1))
        subject.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let cardLayer = await CardLayer(card: Card(rank: .king, suit: .hearts))
        cardLayer.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        let cardLayer2 = await CardLayer(card: Card(rank: .queen, suit: .hearts))
        cardLayer2.frame = CGRect(x: 50, y: 50, width: 50, height: 50)
        subject.layer.addSublayer(cardLayer)
        subject.layer.addSublayer(cardLayer2)
        subject.tintCard(1)
        let tintLayer = try #require(subject.tintLayers.first)
        #expect(tintLayer.superlayer === cardLayer2)
        #expect(tintLayer.frame == CGRect(x: 2, y: 2, width: 46, height: 46))
        #expect(tintLayer.backgroundColor == UIColor.yellow.withAlphaComponent(0.8).cgColor)
        #expect(tintLayer.compositingFilter as? String == "multiplyBlendMode")
    }

    @Test("tintCard: with card index -1, puts tint layer in front of last card layer")
    func tintCardMinusOne() async throws {
        let subject = CardView(location: Location(category: .column, index: 1))
        subject.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let cardLayer = await CardLayer(card: Card(rank: .king, suit: .hearts))
        cardLayer.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        let cardLayer2 = await CardLayer(card: Card(rank: .queen, suit: .hearts))
        cardLayer2.frame = CGRect(x: 50, y: 50, width: 50, height: 50)
        subject.layer.addSublayer(cardLayer)
        subject.layer.addSublayer(cardLayer2)
        subject.tintCard(-1) // *
        let tintLayer = try #require(subject.tintLayers.first)
        #expect(tintLayer.superlayer === cardLayer2)
        #expect(tintLayer.frame == CGRect(x: 2, y: 2, width: 46, height: 46))
        #expect(tintLayer.backgroundColor == UIColor.yellow.withAlphaComponent(0.8).cgColor)
        #expect(tintLayer.compositingFilter as? String == "multiplyBlendMode")
    }

    @Test("removeTintLayers: removes all tint layers")
    func removeTintLayers() async throws {
        let subject = CardView(location: Location(category: .column, index: 1))
        let tintLayer = CALayer()
        let tintLayer2 = CALayer()
        subject.layer.sublayers = [tintLayer, tintLayer2]
        subject.tintLayers = [tintLayer, tintLayer2]
        subject.removeTintLayers()
        #expect(subject.tintLayers.isEmpty)
        #expect(tintLayer.superlayer == nil)
        #expect(tintLayer2.superlayer == nil)
    }
}
