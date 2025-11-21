import UIKit

/// A card view is _where_ cards can appear, but it does not, itself, draw the cards; the cards
/// are drawn by card _layers_. Think of it as a place where a card can go: the foundations, the
/// free cells, and the columns of the layout are all card views. Card views are thus completely
/// stationary; it is the card layers that fly around the interface. Also, a card view is a view,
/// so it is something that can be tapped; card views are the chief things the user interacts with.
class CardView: UIView {
    /// Layout location represented by this card view.
    let location: Location

    /// Reference to the processor.
    weak var processor: (any Receiver<GameAction>)?

    /// Card(s) considered to belong to this view. This view's job is to direct the drawing of
    /// its card(s), though (as I've said) it does not actually _do_ the drawing.
    var cards = [Card]()

    /// List of current tint layers, used for showing same-ranked cards,
    /// so that we can easily remove them all when showing same-ranked cards is over.
    var tintLayers = [CALayer]()

    static var baseSize: CGSize = .zero // will be set when view controller knows view size
    static let cardLayerBorder: CGFloat = 2
    static let cardLayerInset = UIEdgeInsets(
        top: cardLayerBorder,
        left: cardLayerBorder,
        bottom: cardLayerBorder,
        right: cardLayerBorder
    )

    lazy var widthConstraint = widthAnchor.constraint(equalToConstant: 0)
    lazy var heightConstraint = heightAnchor.constraint(equalToConstant: 0)

    /// Layer that appears in the card view if it has no cards.
    lazy var emptyLayer = CALayer().applying {
        $0.frame = CGRect(
            origin: .zero,
            size: CardView.baseSize
        )
        .inset(by: CardView.cardLayerInset)
        .inset(by: CardView.cardLayerInset)
        if location.category == .column {
            $0.frame = $0.frame.offsetBy(dx: 0, dy: -CardView.cardLayerInset.top)
            // looks better somehow, but only for columns
        }
        $0.cornerRadius = 4
        $0.masksToBounds = true
        $0.backgroundColor = UIColor.white.cgColor
        $0.zPosition = -1
    }

    init(location: Location) {
        self.location = location
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let tapper = MyTapGestureRecognizer(target: self, action: #selector(tapped))
        self.addGestureRecognizer(tapper)
        let longPresser = MyLongPressGestureRecognizer(target: self, action: #selector(longPressed))
        longPresser.minimumPressDuration = 0.25
        self.addGestureRecognizer(longPresser)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func redraw(movableCount: Int = 0) async {
        layer.sublayers = nil
        self.layer.addSublayer(emptyLayer)
        if cards.isEmpty {
            emptyLayer.isHidden = false
            alpha = 0.5
        } else {
            emptyLayer.isHidden = true
            switch location.category {
            case .freeCell, .foundation:
                // cards go on top of one another in a simple pile
                for (offset, card) in cards.enumerated() {
                    let cardLayer = await CardLayer(card: card)
                    cardLayer.zPosition = CGFloat(offset)
                    self.layer.addSublayer(cardLayer)
                }
                alpha =  location.category == .freeCell ? 1 : 0.5
            case .column:
                // cards go on top of one another fanned vertically down
                heightConstraint.constant = max(
                    CGFloat(cards.count + 1) * CardView.baseSize.height / 2,
                    CardView.baseSize.height
                )
                for (offset, card) in cards.enumerated() {
                    let cardLayer = await CardLayer(card: card)
                    cardLayer.frame = frame(forCardIndex: offset)
                    cardLayer.zPosition = CGFloat(offset)
                    self.layer.addSublayer(cardLayer)
                }
                if movableCount > 0 {
                    let borderLayer = BorderLayer()
                    // magic numbers adjust so that drawn border occupies card layer inset
                    borderLayer.frame = CGRect(
                        x: 0,
                        y: 1 + CGFloat(cards.count - movableCount) * (CardView.baseSize.height / 2),
                        width: CardView.baseSize.width,
                        height: CGFloat(movableCount + 1) * (CardView.baseSize.height / 2) - 2
                    )
                    borderLayer.zPosition = CGFloat(cards.count)
                    self.layer.addSublayer(borderLayer)
                }
                alpha = 1
            }
        }
    }

    /// Utility that calculates the frame of a card layer within the card view.
    /// - Parameter offset: The offset (index) of the represented card within `cards`.
    /// - Returns: The frame.
    func frame(forCardIndex offset: Int) -> CGRect {
        switch location.category {
        case .foundation, .freeCell:
            return CGRect(origin: .zero, size: CardView.baseSize)
        case .column:
            return CGRect(
                origin: CGPoint(x: 0, y: (CardView.baseSize.height / 2) * CGFloat(offset)),
                size: CardView.baseSize
            )
        }
    }

    /// "Enablement" means (to the user) "you can/can't play to/from here". Used when the user
    /// does the first tap, to show where the second tap might go, and also when the user asks
    /// to see all cards that can play ("hint").
    /// - Parameter enablement: The enablement value to use.
    func setEnablement(_ enablement: GameState.Enablement) {
        switch enablement {
        case .disabled:
            alpha = 0.5
        case .enabled:
            alpha = 1.0
        case .normal: // neutral; neither enabled nor disabled
            if cards.isEmpty {
                alpha = 0.5
            } else {
                alpha = location.category == .foundation ? 0.5 : 1
            }
        }
    }

    @objc func tapped() {
        Task {
            await processor?.receive(.tapped(location))
        }
    }

    @objc func longPressed(_ gestureRecognizer: UIGestureRecognizer) {
        guard !cards.isEmpty else {
            return
        }
        switch gestureRecognizer.state {
        case .began:
            if location.category == .foundation || location.category == .freeCell {
                Task {
                    await processor?.receive(.longPress(location, -1)) // -1 means use `card`
                }
            } else {
                let point = gestureRecognizer.location(in: self)
                let superlayerPoint = convert(point, to: self.superview)
                let hitLayer = layer.hitTest(superlayerPoint)
                if let cardLayer = hitLayer?.superlayer as? CardLayer {
                    Task {
                        await processor?.receive(.longPress(location, Int(cardLayer.zPosition)))
                    }
                }
            }
        case .ended:
            Task {
                await processor?.receive(.longPressEnded)
            }
        default: break
        }
    }

    /// Cover the card at the given index with a yellow overlay, to help the user spot it.
    /// - Parameter index: The card's index, or `-1` to mean the _last_ card (as in the case of
    /// a foundation).
    func tintCard(_ index: Int) {
        let cardLayers = layer.sublayers(ofType: CardLayer.self)
        if let cardLayer = index == -1 ? cardLayers.last : cardLayers[index] {
            let tintLayer = CALayer()
            tintLayer.frame = cardLayer.bounds.insetBy(dx: 2, dy: 2)
            tintLayer.backgroundColor = UIColor.yellow.withAlphaComponent(0.8).cgColor
            tintLayer.compositingFilter = "multiplyBlendMode"
            cardLayer.addSublayer(tintLayer)
            self.tintLayers.append(tintLayer)
        }
    }

    func removeTintLayers() {
        while let tintLayer = tintLayers.popLast() {
            tintLayer.removeFromSuperlayer()
        }
    }

/*
 These methods are called only during an animation. They are purely temporary, and in fact
 deliberately distort the way the card view is drawn, part of a sleight of hand that
 disguises from the user the fact that the card that appears to be moving towards this
 card view is in reality already _in_ the card view. This is coherent only because we
 guarantee that every `hide` call is balanced by a `show` call at the end of the animation.
*/

    /// Temporarily hide the card layer at the given index. If this causes the card view to
    /// appear to have _no_ cards, also show the empty layer.
    /// - Parameter index: The index (within `cards`) of the card layer to be hidden.
    func hideCard(at index: Int) {
        let cardLayers = layer.sublayers(ofType: CardLayer.self)
        if cardLayers.indices.contains(index) {
            cardLayers[index].isHidden = true
        }
        if cardLayers.allSatisfy({ $0.isHidden }) {
            emptyLayer.isHidden = false
            setEnablement(.disabled)
        }
    }

    /// Hide the blue border.
    func hideBorder() { // TODO: But it would be better to revise the border's value?
        if let border = layer.sublayers(ofType: BorderLayer.self).first {
            border.isHidden = true
        }
    }

    /// Show all card layers, restoring the normal drawing of the card view. At the end, we set
    /// the enablement to the standard neutral value, in case we changed it in `hideCards`.
    func showCards() {
        let cardLayers = layer.sublayers(ofType: CardLayer.self)
        cardLayers.forEach {
            $0.isHidden = false
        }
        if cardLayers.count > 0 {
            emptyLayer.isHidden = true
        }
        setEnablement(.normal)
    }

    /// Show the blue border.
    func showBorder() {
        if let border = layer.sublayers(ofType: BorderLayer.self).first {
            border.isHidden = false
        }
    }

}
