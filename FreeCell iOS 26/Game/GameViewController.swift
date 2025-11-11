import UIKit

final class GameViewController: UIViewController, ReceiverPresenter {
    weak var processor: (any Receiver<GameAction>)?

    // Card views

    var foundations: [CardView]!

    var freeCells: [CardView]!

    var columns: [CardView]!

    // Helper objects

    var gameViewMenuBuilder: (any GameViewMenuBuilderType)? = GameViewMenuBuilder()

    var gameViewInterfaceConstructor: (any GameViewInterfaceConstructorType)? = GameViewInterfaceConstructor()

    var gameViewCardSizer: (any GameViewCardSizerType)? = GameViewCardSizer()

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
    }

    var didInitialLayout = false
    override func viewWillLayoutSubviews() {
        if didInitialLayout {
            return
        }
        didInitialLayout = true
        CardView.baseSize = gameViewCardSizer?.cardSize(boardWidth: view.bounds.width) ?? .zero
        let cardViews = gameViewInterfaceConstructor?.constructInterface(in: view)
        self.foundations = cardViews?[0]
        self.freeCells = cardViews?[1]
        self.columns = cardViews?[2]
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
    }

    func receive(_ effect: GameEffect) async {}

    @objc func doDeal() {
        Task {
            await processor?.receive(.deal)
        }
    }

    @objc func doUndo() {}
    @objc func doRedo() {}
    @objc func doUndoAll() {}
    @objc func doRedoAll() {}

    @objc func singleTap() {
        Task {
            await processor?.receive(.tapBackground)
        }
    }

    @objc func doubleTap() {
        Task {
            await processor?.receive(.autoplay)
        }
    }
}
