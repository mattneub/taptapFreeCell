@testable import TTFreeCell
import Testing
import UIKit

private struct CardLayerTests {
    @Test("initialize sets up the layer correctly")
    func initialize() async throws {
        CardView.baseSize = CGSize(
            width: CardImage.sourceImageSize.width/2,
            height: CardImage.sourceImageSize.height/2
        )
        let subject = await CardLayer(card: Card(rank: .jack, suit: .hearts))
        #expect(subject.frame == CGRect(origin: .zero, size: CardView.baseSize))
        #expect(subject.isOpaque == false)
        #expect(subject.backgroundColor == UIColor.clear.cgColor)
        #expect(subject.masksToBounds == true)
        #expect(subject.cornerRadius == 4)
        let cardDrawingLayer = try #require(subject.sublayers?.first)
        #expect(cardDrawingLayer.contentsGravity == .resizeAspect)
        #expect(cardDrawingLayer.cornerRadius == 4)
        #expect(cardDrawingLayer.masksToBounds == true)
        #expect(subject.card == Card(rank: .jack, suit: .hearts))
        #expect(cardDrawingLayer.frame == subject.bounds.inset(by: CardView.cardLayerInset))
        let contents = cardDrawingLayer.contents as! CGImage
        let expected = CardImage.image(for: Card(rank: .jack, suit: .hearts), scale: 2).cgImage
        #expect(contents == expected)
    }
}
