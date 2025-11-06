import UIKit

/// A card view is _where_ cards can appear, but it does not, itself, draw the cards; the cards
/// are drawn by card _layers_. Think of it as a place where a card can go: the foundations, the
/// free cells, and the columns of the layout are all card views. Card views are thus completely
/// stationary; it is the card layers that fly around the interface. Also, a card view is a view,
/// so it is something that can be tapped; card views are the chief things the user interacts with.
final class CardView: UIView {
    /// A `single` card view just sits there like a bump on a log. But a non-`single` card view,
    /// i.e. representing a column, can grow and shrink vertically to represent the overlapping
    /// card layers that it contains.
    let single: Bool

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

    init(single: Bool = true) { // unused
        self.single = single
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        // self.finishInitialConfiguration()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func redraw() {
        // in the case where we have _no_ cards, portray a card-shaped layer to show where the
        // card view is
        layer.sublayers = nil
        if cards.isEmpty {
            let emptyLayer = CALayer().applying {
                $0.frame = CGRect(
                    origin: .zero,
                    size: CardView.baseSize
                )
                .inset(by: CardView.cardLayerInset)
                // inset a little further than an actual card would be
                .inset(by: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2))
                $0.cornerRadius = 4
                $0.masksToBounds = true
                $0.backgroundColor = UIColor.white.cgColor
                $0.zPosition = -1
                $0.opacity = 0.5
            }
            self.layer.addSublayer(emptyLayer)
            self.emptyLayer = emptyLayer
        }
    }

}
