import UIKit
import Confetti

final class GameViewController: UIViewController, ReceiverPresenter {
    weak var processor: (any Receiver<GameAction>)?

    // Card views

    var foundations = [CardView]()

    var freeCells = [CardView]()

    var columns = [CardView]()

    // Highlight layer

    var highlightLayer: CALayer?

    // Helper objects

    var gameViewMenuBuilder: (any GameViewMenuBuilderType)? = GameViewMenuBuilder()

    var gameViewInterfaceConstructor: (any GameViewInterfaceConstructorType)? = GameViewInterfaceConstructor()

    var gameViewCardSizer: (any GameViewCardSizerType)? = GameViewCardSizer()

    // Confetti

    var confetti: ConfettiDropper?

    var confettiTime: Double = 10 // so we can inject a shorter time for testing

    var confettiTask: Task<(), Error>?

    /// Imaginary point off the top of the screen representing the location of the deck.
    /// Deal is animated from this point.
    var deckPoint: CGPoint {
        CGPoint(x: view.bounds.midX, y: -(CardView.baseSize.height))
    }

    /// Label that shows the elapsed time of the game.
    lazy var timerLabel = UILabel().applying {
        $0.text = "00:00:00"
        $0.font = UIFont(name: "ArialRoundedMTBold", size: 16)
        $0.textAlignment = .center
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    /// Glass wrapper containing the timer label.
    lazy var timerGlass = UIVisualEffectView(effect: UIGlassEffect(style: .regular)).applying {
        $0.cornerConfiguration = .capsule()
        $0.contentView.addSubview(timerLabel)
        $0.bounds.size.width = 82
        $0.bounds.size.height = 44
        timerLabel.centerXAnchor.constraint(equalTo: $0.contentView.centerXAnchor).isActive = true
        timerLabel.centerYAnchor.constraint(equalTo: $0.contentView.centerYAnchor).isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let dealButton = UIBarButtonItem(
            title: nil,
            image: UIImage(systemName: "square.3.layers.3d.down.forward"),
            target: self,
            action: #selector(doDeal)
        )
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            menu: gameViewMenuBuilder?.buildMenu()
        )
        navigationItem.leftBarButtonItems = [dealButton, menuButton]

        let undoButton = UIBarButtonItem(
            title: nil,
            image: UIImage(systemName: "arrow.uturn.backward"),
            target: self,
            action: #selector(doUndo)
        )
        undoButton.menu = UIMenu(
            title: "",
            children: [
                UIAction(
                    title: "Undo All",
                    image: UIImage(systemName: "arrow.uturn.backward")
                ) { [weak self] _ in self?.doUndoAll() }
            ]
        )
        let redoButton = UIBarButtonItem(
            title: nil,
            image: UIImage(systemName: "arrow.uturn.forward"),
            target: self,
            action: #selector(doRedo)
        )
        redoButton.menu = UIMenu(
            title: "",
            children: [
                UIAction(
                    title: "Redo All",
                    image: UIImage(systemName: "arrow.uturn.forward")
                ) { [weak self] _ in self?.doRedoAll() }
            ]
        )
        navigationItem.rightBarButtonItems = [redoButton, undoButton]

        navigationItem.titleView = timerGlass

        let imageView = UIImageView().applying {
            $0.image = UIImage(named: "wallpaper.jpg")
        }
        imageView.frame = self.view.bounds
        self.view.insertSubview(imageView, at: 0)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let doubleTapper = MyTapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapper.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapper)
        let singleTapper = MyTapGestureRecognizer(target: self, action: #selector(singleTap))
        singleTapper.numberOfTapsRequired = 1
        view.addGestureRecognizer(singleTapper)
        let twoTapper = MyTapGestureRecognizer(target: self, action: #selector(twoFingerTap))
        twoTapper.numberOfTouchesRequired = 2
        view.addGestureRecognizer(twoTapper)
    }

    var didInitialLayout = false
    override func viewWillLayoutSubviews() {
        if didInitialLayout {
            return
        }
        didInitialLayout = true
        CardView.baseSize = gameViewCardSizer?.cardSize(boardWidth: view.bounds.width) ?? .zero
        if let cardViews = gameViewInterfaceConstructor?.constructInterface(in: view) {
            foundations = cardViews[0]
            freeCells = cardViews[1]
            columns = cardViews[2]
        }
        Task {
            for cardView in foundations + freeCells + columns {
                cardView.processor = self.processor
                await cardView.redraw()
            }
        }
    }

    func present(_ state: GameState) async {
        // reflect layout into card views, skipping card views that do not change
        for index in foundations.indices {
            if foundations[index].cards != state.layout.foundations[index].cards {
                foundations[index].cards = state.layout.foundations[index].cards
                await foundations[index].redraw()
            }
        }
        for index in freeCells.indices {
            if freeCells[index].cards != state.layout.freeCells[index].cards {
                freeCells[index].cards = state.layout.freeCells[index].cards
                await freeCells[index].redraw()
            }
        }
        for index in columns.indices {
            if columns[index].cards != state.layout.columns[index].cards {
                columns[index].cards = state.layout.columns[index].cards
                let movableCount = if state.sequences {
                    state.layout.columns[index].maxMovableSequence.count
                } else {
                    0
                }
                await columns[index].redraw(movableCount: movableCount)
            }
        }
        if state.highlightOn, let location = state.firstTapLocation {
            await highlight(location, tint: state.tintTapped, grow: state.growTapped)
        } else {
            highlightLayer?.removeFromSuperlayer()
            highlightLayer = nil
        }
        for (location, enablement) in state.enablements {
            let group = group(for: location)
            if group.indices.contains(location.index) {
                group[location.index].setEnablement(enablement)
            }
        }
    }

    func receive(_ effect: GameEffect) async {
        switch effect {
        case .animate(let moves, let duration):
            guard !moves.isEmpty else {
                return // nothing to do
            }
            await animate(moves, duration: duration)
        case .confetti:
            self.confetti = ConfettiDropper(displayScale: traitCollection.displayScale)
            confetti?.addEmitter(to: view)
            self.confettiTask = Task { // in case user doesn't stop the confetti manually
                try await Task.sleep(for: .seconds(confettiTime))
            }
            try? await confettiTask?.value
            ensureNoConfetti()
        case .removeConfetti:
            ensureNoConfetti()
        case .tint(let locationsAndCards):
            tint(locationsAndCards)
        case .tintsOff:
            removeAllTints()
        case .updateStopwatch(let timeInterval):
            if let string = Stopwatch.timeTakenFormatter.string(from: timeInterval) {
                timerLabel.text = string
            }
        }
    }

    func tint(_ locationsAndCards: [LocationAndCard]) {
        for locationAndCard in locationsAndCards {
            let location = locationAndCard.location
            let cardView = cardView(for: location)
            if location.category == .foundation || location.category == .freeCell {
                cardView.tintCard(-1) // meaning last card
            } else {
                cardView.tintCard(locationAndCard.internalIndex)
            }
        }
    }

    func removeAllTints() {
        for cardView in (foundations + freeCells + columns) {
            cardView.removeTintLayers()
        }
    }

    func ensureNoConfetti() {
        self.confettiTask?.cancel()
        self.confetti?.removeEmitter()
        self.confetti = nil
    }

    @objc func doDeal() {
        ensureNoConfetti()
        Task {
            await processor?.receive(.deal)
        }
    }

    @objc func doUndo() {
        ensureNoConfetti()
        Task {
            await processor?.receive(.undo)
        }
    }

    @objc func doRedo() {
        ensureNoConfetti()
        Task {
            await processor?.receive(.redo)
        }
    }

    @objc func doUndoAll() {
        ensureNoConfetti()
        Task {
            await processor?.receive(.undoAll)
        }
    }

    @objc func doRedoAll() {
        ensureNoConfetti()
        Task {
            await processor?.receive(.redoAll)
        }
    }

    @objc func singleTap() {
        ensureNoConfetti()
        Task {
            await processor?.receive(.tapBackground)
        }
    }

    @objc func doubleTap() {
        ensureNoConfetti()
        Task {
            await processor?.receive(.autoplay)
        }
    }

    @objc func twoFingerTap() {
        ensureNoConfetti()
        Task {
            await processor?.receive(.hint)
        }
    }

    func group(for location: Location) -> [CardView] {
        switch location.category {
        case .foundation: foundations
        case .freeCell: freeCells
        case .column: columns
        }
    }

    func cardView(for location: Location) -> CardView {
        group(for: location)[location.index]
    }

    func highlight(_ location: Location, tint: Bool, grow: Bool) async {
        let cardView = cardView(for: location)
        let highlightLayer = CALayer()
        highlightLayer.contentsScale = self.traitCollection.displayScale + 1
        highlightLayer.isOpaque = true
        highlightLayer.frame = cardView.frame
        let size = highlightLayer.bounds.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = highlightLayer.contentsScale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            cardView.layer.render(in: context.cgContext)
            if tint {
                UIColor.highlightColor.setFill()
                context.fill(CGRect(origin: .zero, size: size), blendMode: .multiply)
            }
        }
        highlightLayer.contents = image.cgImage
        highlightLayer.zPosition = 2000
        cardView.superview?.layer.addSublayer(highlightLayer)
        CATransaction.flush()
        if grow { // deliberately do not await this because that delays enablement
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.1)
            highlightLayer.transform = CATransform3DMakeScale(1.15, 1.15, 1)
            CATransaction.commit()
        }
        self.highlightLayer = highlightLayer
    }
    
    /// Animate an enactment of the card moves described in the Moves list, using "fake" card
    /// layers. *Assumption*: The _real_ card layers have _already_ been removed from their
    /// source card views and have _already_ been created in their destination card views.
    /// - Parameters:
    ///   - moves: The list of moves.
    ///   - duration: The animation duration.
    func animate(_ moves: [Move], duration: Double) async {
        // when testing, it helps to insert a fake duration, e.g. `let duration = 1.0`, so you
        // can get a good look at the animation
        view.isUserInteractionEnabled = false
        // before doing anything else, collect all the different ranks of all the moving cards;
        // we will need this in order to stagger the launch of cards moving to foundations
        let ranks = Set(moves.map { $0.destination.card.rank }).sorted { $0.rawValue < $1.rawValue }
        // local struct that collects all the info needed to perform the actual animation
        struct MoveInfo {
            let layer: CardLayer
            let oldPosition: CGPoint
            let newPosition: CGPoint
            let newCardView: CardView
            let newInternalIndex: Int
        }
        var infos = [MoveInfo]()
        var dealing = false
        // prepare all the calculated info needed to perform the animation
        for move in moves {
            let oldCardView = cardView(for: move.source.location)
            let oldInternalIndex = move.source.internalIndex
            let newCardView = cardView(for: move.destination.location)
            let newInternalIndex = move.destination.internalIndex
            newCardView.hideCard(at: newInternalIndex)
            newCardView.hideBorder()
            let cardLayer = await CardLayer(card: move.source.card)
            cardLayer.zPosition = CGFloat(move.source.internalIndex) // i.e exactly where the old real card layer was
            let oldCardLayerFrame = oldCardView.convert(
                oldCardView.frame(forCardIndex: oldInternalIndex),
                to: view
            )
            let newCardLayerFrame = newCardView.convert(
                newCardView.frame(forCardIndex: newInternalIndex),
                to: view
            )
            // equality of old frame and new frame is a signal that this card arrives from the deck
            if oldCardLayerFrame == newCardLayerFrame {
                dealing = true
            }
            let info = MoveInfo(
                layer: cardLayer,
                oldPosition: dealing ? deckPoint : oldCardLayerFrame.center,
                newPosition: newCardLayerFrame.center,
                newCardView: newCardView,
                newInternalIndex: move.destination.internalIndex
            )
            infos.append(info)
        }
        // we now have all the information; the animation now begins!
        // insert all moving cards into the visible interface at the _old_ positions / zPositions
        infos.forEach {
            view.layer.addSublayer($0.layer)
        }
        // animate all moving cards to their _new_ positions / zPositions
        await TransactionWaiter.shared.perform {
            CATransaction.setDisableActions(true) // in case we set an animatable property directly
            for info in infos {
                // group
                let group = CAAnimationGroup()
                group.duration = duration
                group.beginTime = CACurrentMediaTime() + 0.01
                group.timingFunction = if duration < 0.15 {
                    CAMediaTimingFunction(name: .linear)
                } else {
                    CAMediaTimingFunction(controlPoints: 0.9, 0.1, 0.7, 0.9)
                }
                // normally, I would scold anyone who uses this trick; but here it is safe and
                // acceptable, because what we are animating is a _fake_ layer which _itself_
                // will be removed when the animation is over
                // furthermore, this setting is _inherited_, so we don't need to repeat it
                // for the child animations; they _all_ fill both backwards and forwards
                group.fillMode = .both
                group.isRemovedOnCompletion = false
                // accumulate desired animations into an array to be set as the group's animations
                var animations = [CAAnimation]()
                // move
                let move = CABasicAnimation(keyPath: #keyPath(CALayer.position))
                move.fromValue = info.oldPosition
                move.toValue = info.newPosition
                animations.append(move)
                // waggle (transforms: subtle grow-shrink, rotate-and-back, shift-and-back)
                let waggle = CABasicAnimation(keyPath: #keyPath(CALayer.transform))
                waggle.duration = duration / 2.0
                waggle.autoreverses = true
                waggle.fromValue = CATransform3DIdentity
                var transform = CATransform3DMakeScale(1.2, 1.2, 1)
                transform = CATransform3DRotate(transform, .pi/35, 0, 0, 1)
                transform = CATransform3DTranslate(transform, -(info.layer.bounds.width/6), 0, 0)
                waggle.toValue = transform
                animations.append(waggle)
                // zPosition
                let zPosition = CABasicAnimation(keyPath: #keyPath(CALayer.zPosition))
                zPosition.fromValue = info.layer.zPosition
                zPosition.toValue = CGFloat(info.newInternalIndex) + 0.5 // just in front of real card
                // we now face a little problem: let's say we are moving 5 cards from a column to
                // a foundation; they will all essential reverse their zPositions, and we don't
                // want that to happen right at the start or end, or indeed at any obstreperous
                // instant — so we not only animate but randomly stagger the change
                zPosition.duration = duration / Double.random(in: 2...8) // cool
                zPosition.beginTime = duration - zPosition.duration
                animations.append(zPosition)
                // things we do for foundations only
                if info.newCardView.location.category == .foundation {
                    // fade, because the foundation is faded
                    let fade = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
                    fade.fromValue = 1.0
                    fade.toValue = 0.5
                    fade.duration = duration / 2.0
                    fade.beginTime = duration / 2.0 // don't start to fade until halfway thru
                    animations.append(fade)
                    // and now my absolute favorite part: stagger the animation launches
                    // so that lower ranks start moving earlier than higher ranks
                    if let offset = ranks.firstIndex(of: info.layer.card.rank) {
                        group.beginTime += (duration / 4.0) * Double(offset)
                    }
                }
                // the end! wrap it all up and add it to the layer
                group.animations = animations
                info.layer.add(group, forKey: nil)
            }
        }
        // dance to prevent flash as we remove the moving cards and reveal the _real_ cards
        // which are already in place
        await TransactionWaiter.shared.perform {
            CATransaction.setDisableActions(true)
            infos.forEach {
                $0.newCardView.showCards()
                $0.newCardView.showBorder()
            }
        }
        await TransactionWaiter.shared.perform {
            CATransaction.setDisableActions(true)
            infos.forEach {
                $0.layer.isHidden = true
            }
        }
        infos.forEach {
            $0.layer.removeFromSuperlayer()
        }
        view.isUserInteractionEnabled = true
    }
}
