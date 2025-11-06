import UIKit

/// A card is physically drawn by a card _layer_. A card layer will usually appear within a
/// card view, but it is not that card view's layer, and it can be freely animated from one
/// card view to another.
nonisolated
final class CardLayer: CALayer {
    let card: Card

    init(card: Card) async {
        self.card = card
        super.init()
        self.frame = CGRect(origin: .zero, size: await CardView.baseSize)
        self.isOpaque = false
        self.backgroundColor = UIColor.clear.cgColor
        self.masksToBounds = true
        self.cornerRadius = 4
        let cardDrawingLayer = CALayer() // actual drawing of card is portrayed inset from the layer
        self.addSublayer(cardDrawingLayer)
        cardDrawingLayer.contentsGravity = .resizeAspect
        cardDrawingLayer.cornerRadius = 4
        cardDrawingLayer.masksToBounds = true
        cardDrawingLayer.frame = self.bounds.inset(by: await CardView.cardLayerInset)
        // TODO: fix scale
        cardDrawingLayer.contents = (await CardImage.image(for: card, scale: 2)).cgImage
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(layer other: Any) {
        guard let other = other as? CardLayer else {
            fatalError("shouldn't happen")
        }
        self.card = other.card
        super.init(layer: other) // and everything else magically carries across
    }
}
