import UIKit

/// A card view is _where_ cards can appear, but it does not, itself, draw the cards; the cards
/// are drawn by card _layers_. Think of it as a place where a card can go: the foundations, the
/// free cells, and the columns of the layout are all card views. Card views are thus completely
/// stationary; it is the card layers that fly around the interface. Also, a card view is a view,
/// so it is something that can be tapped; card views are the chief things the user interacts with.
final class CardView: UIView {
    /// Which of the three types of card view this is.
    let category: Category

    /// The index of this card view within the sequence of its category fellows. The view needs
    /// to know this so that it can report taps in a helpful way.
    let index: Int

    /// Reference to the processor.
    weak var processor: (any Receiver<GameAction>)?

    /// Card(s) considered to belong to this view. This view's job is to direct the drawing of
    /// its card(s), though (as I've said) it does not actually _do_ the drawing.
    var cards = [Card]()

    /// Layer that represents that no cards are present.
    weak var emptyLayer: CALayer?

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

    init(category: Category, index: Int) {
        self.category = category
        self.index = index
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let tapper = MyTapGestureRecognizer(target: self, action: #selector(tapped))
        self.addGestureRecognizer(tapper)
        // self.finishInitialConfiguration()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func redraw(movableCount: Int = 0) async {
        layer.sublayers = nil
        if cards.isEmpty {
            // in the case where we have _no_ cards, portray a card-shaped layer to show where the
            // card view is
            let emptyLayer = CALayer().applying {
                $0.frame = CGRect(
                    origin: .zero,
                    size: CardView.baseSize
                )
                .inset(by: CardView.cardLayerInset)
                .inset(by: CardView.cardLayerInset)
                if category == .column {
                    $0.frame = $0.frame.offsetBy(dx: 0, dy: -CardView.cardLayerInset.top)
                    // looks better somehow, but only for columns
                }
                $0.cornerRadius = 4
                $0.masksToBounds = true
                $0.backgroundColor = UIColor.white.cgColor
                $0.zPosition = -1
                $0.opacity = 0.5
            }
            self.layer.addSublayer(emptyLayer)
            self.emptyLayer = emptyLayer
        } else {
            switch category {
            case .foundation, .freeCell:
                if let card = cards.last {
                    let cardLayer = await CardLayer(card: card)
                    self.layer.addSublayer(cardLayer)
                    cardLayer.opacity = category == .freeCell ? 1 : 0.5
                }
            case .column:
                // this is the Really Interesting Part
                heightConstraint.constant = max(
                    CGFloat(cards.count + 1) * CardView.baseSize.height / 2,
                    CardView.baseSize.height
                )
                for (offset, card) in cards.enumerated() {
                    let cardLayer = await CardLayer(card: card)
                    cardLayer.frame.origin.y = (CardView.baseSize.height / 2) * CGFloat(offset)
                    cardLayer.zPosition = CGFloat(offset)
                    self.layer.addSublayer(cardLayer)
                }
                if movableCount > 0 {
                    let borderLayer = CALayer()
                    borderLayer.borderColor = UIColor.blue.cgColor
                    borderLayer.borderWidth = 2
                    borderLayer.frame = CGRect(
                        x: 0,
                        y: (
                            CardView.cardLayerInset.top +
                            CGFloat(cards.count - movableCount) * (CardView.baseSize.height / 2)
                        ),
                        width: CardView.baseSize.width,
                        height: (
                            CGFloat(movableCount + 1) * (CardView.baseSize.height / 2) -
                            CardView.cardLayerInset.top -
                            CardView.cardLayerInset.bottom
                        )
                    )
                    borderLayer.zPosition = CGFloat(cards.count)
                    borderLayer.cornerRadius = 4
                    self.layer.addSublayer(borderLayer)
                }
            }
        }
    }

    @objc func tapped() {
        Task {
            await processor?.receive(.tapped(category: category, index: index))
        }
    }

    /// The layout category represented by this card view.
    enum Category: Equatable {
        case column
        case freeCell
        case foundation(Suit)
    }
}
