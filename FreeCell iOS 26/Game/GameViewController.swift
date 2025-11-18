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
        for index in 0..<4 {
            if foundations[index].cards != state.layout.foundations[index].cards {
                foundations[index].cards = state.layout.foundations[index].cards
                await foundations[index].redraw()
            }
            if freeCells[index].cards != state.layout.freeCells[index].cards {
                freeCells[index].cards = state.layout.freeCells[index].cards
                await freeCells[index].redraw()
            }
        }
        for index in 0..<8 {
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
            let cardView = groupFor(location)[location.index]
            cardView.setEnablement(enablement)
        }
    }

    func receive(_ effect: GameEffect) async {
        switch effect {
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
            let cardView = groupFor(location)[location.index]
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

    func groupFor(_ location: Location) -> [CardView] {
        switch location.category {
        case .foundation: foundations
        case .freeCell: freeCells
        case .column: columns
        }
    }

    func highlight(_ location: Location, tint: Bool, grow: Bool) async {
        let cardView = groupFor(location)[location.index]
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

}
