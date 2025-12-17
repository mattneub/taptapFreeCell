@testable import TTFreeCell
import Testing
import UIKit
import WaitWhile

private struct GameViewControllerTests {
    let subject = GameViewController()
    let sizer = MockGameViewCardSizer()
    let constructor = MockGameViewInterfaceConstructor()
    let builder = MockGameViewMenuBuilder()
    let processor = MockReceiver<GameAction>()
    let debouncer = MockDebouncer(interval: 0.2, delegate: nil)

    init() {
        subject.gameViewCardSizer = sizer
        subject.gameViewInterfaceConstructor = constructor
        subject.gameViewMenuBuilder = builder
        subject.processor = processor
        subject.debouncer = debouncer
    }

    @Test("deckPoint: is correctly defined in terms of view bounds and card size")
    func deckPoint() {
        sizer.sizeToReturn = CGSize(width: 50, height: 100)
        subject.view.bounds.size.width = 400
        subject.viewWillLayoutSubviews()
        #expect(subject.deckPoint == CGPoint(x: 200, y: -100)) // half view width, twice card height
    }

    @Test("timerLabel is correctly constructed")
    func timerLabel() throws {
        let label = subject.timerLabel
        #expect(label.text == "00:00:00")
        #expect(label.font == UIFont(name: "ArialRoundedMTBold", size: 16))
        #expect(label.textAlignment == .center)
        #expect(label.translatesAutoresizingMaskIntoConstraints == false)
        #expect(label.constraints.count == 2)
        let width = try #require(label.constraints.first(where: { $0.firstAttribute == .width }))
        #expect(width.constant == 90)
        let height = try #require(label.constraints.first(where: { $0.firstAttribute == .height }))
        #expect(height.constant == 44)
    }

    @Test("timerGlass is correctly constructed")
    func timerGlass() {
        let glass = subject.timerGlass
        #expect(glass.translatesAutoresizingMaskIntoConstraints == false)
        #expect(glass.cornerConfiguration == .capsule())
        let label = subject.timerLabel
        #expect(label.isDescendant(of: glass))
        let viewController = UIViewController()
        makeWindow(viewController: viewController)
        viewController.view.addSubview(glass)
        glass.layoutIfNeeded()
        #expect(glass.bounds.size.width == 90)
        #expect(glass.bounds.size.height == 44)
        #expect(label.bounds.size.width == 90)
        #expect(label.bounds.size.height == 44)
    }

    @Test("viewDidLoad: configures bar button items, adds image view, tap gesture recognizers")
    func viewDidLoad() throws {
        subject.loadViewIfNeeded()
        #expect(subject.title == nil)
        #expect(subject.navigationItem.backBarButtonItem?.title == "Game")
        let lefts = try #require(subject.navigationItem.leftBarButtonItems)
        #expect(lefts.count == 2)
        #expect(lefts[0].title == nil)
        #expect(lefts[0].image == UIImage(systemName: "square.3.layers.3d.down.forward"))
        #expect(lefts[0].target === subject)
        #expect(lefts[0].action == #selector(subject.doDeal))
        #expect(lefts[1].title == nil)
        #expect(lefts[1].image == UIImage(systemName: "ellipsis"))
        #expect(lefts[1].target == nil)
        #expect(lefts[1].action == nil)
        #expect(lefts[1].menu?.title == "title")
        #expect(builder.methodsCalled == ["buildMenu(processor:)"])
        #expect(builder.processor === processor)
        let rights = try #require(subject.navigationItem.rightBarButtonItems)
        #expect(rights.count == 2)
        #expect(rights[0].title == nil)
        #expect(rights[0].image == UIImage(systemName: "arrow.uturn.forward"))
        #expect(rights[0].target === subject)
        #expect(rights[0].action == #selector(subject.doRedo))
        let menu0 = try #require(rights[0].menu)
        #expect(menu0.title == "")
        #expect(menu0.children.count == 1)
        let menu0action = try #require(menu0.children[0] as? UIAction)
        #expect(menu0action.title == "Redo All")
        #expect(menu0action.image == UIImage(systemName: "arrow.uturn.forward"))
        // will test handler later
        #expect(rights[1].title == nil)
        #expect(rights[1].image == UIImage(systemName: "arrow.uturn.backward"))
        #expect(rights[1].target === subject)
        #expect(rights[1].action == #selector(subject.doUndo))
        let menu1 = try #require(rights[1].menu)
        #expect(menu1.title == "")
        #expect(menu1.children.count == 1)
        let menu1action = try #require(menu1.children[0] as? UIAction)
        #expect(menu1action.title == "Undo All")
        #expect(menu1action.image == UIImage(systemName: "arrow.uturn.backward"))
        // will test handler later
        let imageView = try #require(subject.view.subviews(ofType: UIImageView.self).first)
        #expect(imageView.image == UIImage(named: "wallpaper.jpg"))
        #expect(imageView.frame == subject.view.bounds)
        #expect(imageView.superview === subject.view)
        #expect(imageView.autoresizingMask == [.flexibleWidth, .flexibleHeight])
        let tapper = try #require(subject.view.gestureRecognizers?[0] as? MyTapGestureRecognizer)
        #expect(tapper.numberOfTapsRequired == 2)
        #expect(tapper.numberOfTouchesRequired == 1)
        #expect(tapper.target === subject)
        #expect(tapper.action == #selector(subject.doubleTap))
        let tapper2 = try #require(subject.view.gestureRecognizers?[1] as? MyTapGestureRecognizer)
        #expect(tapper2.numberOfTapsRequired == 1)
        #expect(tapper2.numberOfTouchesRequired == 1)
        #expect(tapper2.target === subject)
        #expect(tapper2.action == #selector(subject.singleTap))
        let tapper3 = try #require(subject.view.gestureRecognizers?[2] as? MyTapGestureRecognizer)
        #expect(tapper3.numberOfTapsRequired == 1)
        #expect(tapper3.numberOfTouchesRequired == 2)
        #expect(tapper3.target === subject)
        #expect(tapper3.action == #selector(subject.twoFingerTap))
    }

    @Test("view will layout: first time only, calls card sizer, interface constructor, calls processor didInitialLayout")
    func viewWillLayout() async throws {
        sizer.sizeToReturn = CGSize(width: 50, height: 100)
        subject.view.bounds.size.width = 400
        subject.viewWillLayoutSubviews()
        #expect(sizer.methodsCalled == ["cardSize(boardWidth:)"])
        #expect(sizer.boardWidth == 400)
        #expect(CardView.baseSize == CGSize(width: 50, height: 100))
        #expect(constructor.methodsCalled == ["constructInterface(in:)"])
        #expect(constructor.view === subject.view)
        let foundation = try #require(subject.foundations.first)
        #expect(foundation.location.category == .foundation)
        let freeCell = try #require(subject.freeCells.first)
        #expect(freeCell.location.category == .freeCell)
        let column = try #require(subject.columns.first)
        #expect(column.location.category == .column)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.didInitialLayout])
        sizer.methodsCalled = []
        constructor.methodsCalled = []
        processor.thingsReceived = []
        subject.viewWillLayoutSubviews()
        #expect(sizer.methodsCalled.isEmpty)
        #expect(constructor.methodsCalled.isEmpty)
        try? await Task.sleep(for: .seconds(0.1))
        #expect(processor.thingsReceived.isEmpty)
    }

    @Test("view will layout: configures all card views as empty, sets processor; card views category and index are right")
    func viewWillLayoutRedraw() async throws {
        constructor.cardViews =  [
            [
                MockCardView(location: Location(category: .foundation, index: 0)),
                MockCardView(location: Location(category: .foundation, index: 1)),
            ],
            [
                MockCardView(location: Location(category: .freeCell, index: 0)),
                MockCardView(location: Location(category: .freeCell, index: 1)),
            ],
            [
                MockCardView(location: Location(category: .column, index: 0)),
                MockCardView(location: Location(category: .column, index: 1)),
            ]
        ]
        subject.viewWillLayoutSubviews()
        #expect(subject.foundations.count == 2)
        #expect(subject.foundations.enumerated().allSatisfy { offset, foundation in
            foundation.location.index == offset &&
            foundation.location.category == .foundation
        })
        #expect(subject.freeCells.count == 2)
        #expect(subject.freeCells.enumerated().allSatisfy { offset, freeCell in
            freeCell.location.index == offset &&
            freeCell.location.category == .freeCell
        })
        #expect(subject.columns.count == 2)
        #expect(subject.columns.enumerated().allSatisfy { offset, column in
            column.location.index == offset &&
            column.location.category == .column
        })
        let allCards = try #require((subject.foundations + subject.freeCells + subject.columns) as? [MockCardView])
        #expect(allCards.allSatisfy { $0.cards.isEmpty })
        await #while(!(allCards.allSatisfy { $0.processor === processor }))
        #expect(allCards.allSatisfy { $0.processor === processor })
    }

    @Test("viewIsAppearing: normally does nothing")
    func viewIsAppearingNormal() throws {
        sizer.sizeToReturn = CGSize(width: 50, height: 100)
        subject.view.bounds.size.width = 400
        subject.viewWillLayoutSubviews()
        subject.viewIsAppearing(false)
        let foundation = try #require(subject.foundations.first)
        #expect(foundation.location.category == .foundation)
        #expect(debouncer.methodsCalled.isEmpty)
    }

    @Test("viewIsAppearing: if stored width non-nil and different from view width, empties interface, calls debouncer")
    func viewIsAppearingSizeChanmged() throws {
        sizer.sizeToReturn = CGSize(width: 50, height: 100)
        subject.view.bounds.size.width = 400
        subject.viewWillLayoutSubviews()
        subject.lastWidth = 500
        subject.viewIsAppearing(false)
        #expect(subject.foundations.isEmpty)
        #expect(subject.view.subviews.count == 1) // image view
        #expect(debouncer.methodsCalled == ["eventOccurred()"])
    }

    @Test("viewDidAppear: attaches long press gesture recognizer to left bar button item view")
    func viewDidAppearLongPresser() async throws {
        let window = makeWindow(viewController: UINavigationController(rootViewController: subject))
        window.layoutIfNeeded()
        subject.viewDidAppear(false)
        let leftItem = try #require(subject.navigationItem.leftBarButtonItem)
        let leftItemView = try #require(leftItem.value(forKey: "view") as? UIView)
        let longPresser = try #require(leftItemView.gestureRecognizers?.last as? MyLongPressGestureRecognizer)
        #expect(longPresser.target === subject)
        #expect(longPresser.action == #selector(subject.doMicrosoftDeal))
        let count = leftItemView.gestureRecognizers!.count
        subject.viewDidAppear(false)
        #expect(leftItemView.gestureRecognizers!.count == count) // we don't add twice
    }

    @Test("viewWillDisappear: writes down current width")
    func viewWillDisappear() {
        subject.view.bounds.size.width = 400
        #expect(subject.lastWidth == nil)
        subject.viewWillDisappear(false)
        #expect(subject.lastWidth == 400)
    }

    @Test("present: distributes state layout cards into card views, tells them to redraw")
    func present() async throws {
        var layout = Layout()
        layout.foundations[0].cards = [Card(rank: .ace, suit: .spades)]
        layout.freeCells[0].cards = [Card(rank: .king, suit: .hearts)]
        layout.columns[0].cards = [
            Card(rank: .jack, suit: .hearts),
            Card(rank: .ten, suit: .clubs)
        ]
        subject.viewWillLayoutSubviews()
        await subject.present(GameState(layout: layout, prefs: [.showSequences: false]))
        let foundationCard = try #require(subject.foundations.first as? MockCardView)
        #expect(foundationCard.cards == [Card(rank: .ace, suit: .spades)])
        #expect(foundationCard.methodsCalled == ["redraw(movableCount:)"])
        #expect(foundationCard.movableCount == 0)
        let freeCellCard = try #require(subject.freeCells.first as? MockCardView)
        #expect(freeCellCard.cards == [Card(rank: .king, suit: .hearts)])
        #expect(freeCellCard.methodsCalled == ["redraw(movableCount:)"])
        #expect(freeCellCard.movableCount == 0)
        let columnCard = try #require(subject.columns.first as? MockCardView)
        #expect(columnCard.cards == [
            Card(rank: .jack, suit: .hearts),
            Card(rank: .ten, suit: .clubs)
        ])
        #expect(columnCard.methodsCalled == ["redraw(movableCount:)"])
        #expect(columnCard.movableCount == 0)
    }

    @Test("present: distributes state layout cards into card views, tells them to redraw with borders")
    func presentBorders() async throws {
        var layout = Layout()
        layout.foundations[0].cards = [Card(rank: .ace, suit: .spades)]
        layout.freeCells[0].cards = [Card(rank: .king, suit: .hearts)]
        layout.columns[0].cards = [
            Card(rank: .jack, suit: .hearts),
            Card(rank: .ten, suit: .clubs)
        ]
        subject.viewWillLayoutSubviews()
        await subject.present(GameState(layout: layout, prefs: [.showSequences: true]))
        let foundationCard = try #require(subject.foundations.first as? MockCardView)
        #expect(foundationCard.cards == [Card(rank: .ace, suit: .spades)])
        #expect(foundationCard.methodsCalled == ["redraw(movableCount:)"])
        #expect(foundationCard.movableCount == 0)
        let freeCellCard = try #require(subject.freeCells.first as? MockCardView)
        #expect(freeCellCard.cards == [Card(rank: .king, suit: .hearts)])
        #expect(freeCellCard.methodsCalled == ["redraw(movableCount:)"])
        #expect(freeCellCard.movableCount == 0)
        let columnCard = try #require(subject.columns.first as? MockCardView)
        #expect(columnCard.cards == [
            Card(rank: .jack, suit: .hearts),
            Card(rank: .ten, suit: .clubs)
        ])
        #expect(columnCard.methodsCalled == ["redraw(movableCount:)"])
        #expect(columnCard.movableCount == 2) // *
    }

    @Test("present: distributes and redraws if nothing changed, but only if in a window")
    func presentNoChange() async throws {
        var layout = Layout()
        layout.columns[0].cards = [
            Card(rank: .jack, suit: .hearts),
            Card(rank: .ten, suit: .clubs)
        ]
        subject.viewWillLayoutSubviews()
        let columnCard = try #require(subject.columns.first as? MockCardView)
        columnCard.cards = [
            Card(rank: .jack, suit: .hearts),
            Card(rank: .ten, suit: .clubs)
        ]
        await subject.present(GameState(layout: layout, prefs: [.showSequences: false]))
        #expect(columnCard.methodsCalled == ["redraw(movableCount:)"])
        // part two
        makeWindow(viewController: subject)
        columnCard.methodsCalled = []
        await subject.present(GameState(layout: layout, prefs: [.showSequences: false]))
        #expect(columnCard.methodsCalled == [])
    }

    @Test("present: if highlightOn false, removes and nilifies highlightLayer")
    func presentHighlightOnFalse() async {
        subject.viewWillLayoutSubviews()
        let layer = CALayer()
        subject.view.layer.addSublayer(layer)
        subject.highlightLayer = layer
        await subject.present(GameState())
        #expect(subject.highlightLayer == nil)
        #expect(layer.superlayer == nil)
    }

    @Test("present: if highlightOn true, adds and configures highlightLayer, applying grow transform")
    func presentHighlightOnTrue() async throws {
        subject.view.bounds.size.width = 400
        subject.gameViewCardSizer = GameViewCardSizer()
        subject.gameViewInterfaceConstructor = GameViewInterfaceConstructor()
        makeWindow(viewController: subject)
        subject.view.layoutIfNeeded()
        await subject.present(
            GameState(
                prefs: [.growTappedCard: true],
                firstTapLocation: Location(category: .column, index: 0)
            )
        )
        let layer = try #require(subject.highlightLayer)
        #expect(layer.superlayer === subject.columns[0].layer.superlayer)
        #expect(layer.frame.integral == subject.columns[0].layer.frame.insetBy(dx: -2, dy: -5).integral)
        #expect(layer.zPosition == 2000)
    }

    @Test("present: sets card view enablements")
    func presentEnablements() async throws {
        makeWindow(viewController: subject)
        subject.viewWillLayoutSubviews()
        let allCards = try #require((subject.foundations + subject.freeCells + subject.columns) as? [MockCardView])
        var state = GameState()
        state.enablements = state.baseEnablements
        await subject.present(state)
        #expect(allCards.allSatisfy { $0.methodsCalled.last == "setEnablement(_:)" })
        #expect(allCards.allSatisfy { $0.enablement == .normal })
    }

    @Test("present: shows or hides clock")
    func showClock() async {
        var state = GameState()
        state[.showClock] = true
        await subject.present(state)
        #expect(subject.navigationItem.titleView === subject.timerGlass)
        state[.showClock] = false
        await subject.present(state)
        #expect(subject.navigationItem.titleView == nil)
    }

    @Test("doDeal: sends deal")
    func doDeal() async {
        subject.doDeal()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.deal])
    }

    @Test("doMicrosoftDeal: sends showMicrosoft")
    func doMicrosoftDeal() async throws {
        let window = makeWindow(viewController: UINavigationController(rootViewController: subject))
        window.layoutIfNeeded()
        subject.viewDidAppear(false)
        let leftItem = try #require(subject.navigationItem.leftBarButtonItem)
        let leftItemView = try #require(leftItem.value(forKey: "view") as? UIView)
        let presser = try #require(leftItemView.gestureRecognizers?.last as? MyLongPressGestureRecognizer)
        presser.state = .began // this calls `action` on `target` for us
        await #while(processor.thingsReceived.count < 2)
        guard case .showMicrosoft(let wrapper) = processor.thingsReceived[1] else {
            throw NSError(domain: "oops", code: 0)
        }
        #expect(wrapper.sourceItem === leftItem)
    }

    @Test("singleTap: sends tapBackground")
    func singleTap() async {
        subject.singleTap()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.tapBackground])
    }

    @Test("doubleTap: sends autoplay")
    func doubleTap() async {
        subject.doubleTap()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.autoplay])
    }

    @Test("twoFingerTap: sends hint")
    func twoFingerTap() async {
        subject.twoFingerTap()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.hint])
    }

    @Test("doUndo: sends undo")
    func undo() async {
        subject.doUndo()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.undo])
    }

    @Test("doRedo: sends redo")
    func redo() async {
        subject.doRedo()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.redo])
    }

    @Test("doUndoAll: sends undoAll")
    func undoAll() async {
        subject.doUndoAll()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.undoAll])
    }

    @Test("doRedoAll: sends redoAll")
    func redoAll() async {
        subject.doRedoAll()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.redoAll])
    }

    @Test("receive animate: calls hide/show index/border on destination card(s)")
    func animate() async throws {
        subject.loadViewIfNeeded()
        subject.viewWillLayoutSubviews()
        subject.foundations[0].cards = [
            Card(rank: .ace, suit: .spades),
            Card(rank: .two, suit: .spades),
            Card(rank: .three, suit: .spades),
        ]
        let move = Move(
            source: LocationAndCard(
                location: Location(category: .column, index: 0),
                internalIndex: 0,
                card: Card(rank: .three, suit: .spades)
            ),
            destination: LocationAndCard(
                location: Location(category: .foundation, index: 0),
                internalIndex: 2,
                card: Card(rank: .three, suit: .spades)
            )
        )
        await subject.receive(.animate([move], duration: 0.05))
        let destination = try #require(subject.foundations[0] as? MockCardView)
        #expect(destination.methodsCalled == [
            "hideCard(at:)", "hideBorder()", "showCards()", "showBorder()"
        ])
        #expect(destination.hideCardIndex == 2)
        // that's really all we can test; by the time we return from `await`, the fake card layers
        // have all been removed, the animations are gone, etc.
    }

    @Test("receive animate: with empty moves does nothing")
    func animateNoMoves() async throws {
        subject.loadViewIfNeeded()
        subject.viewWillLayoutSubviews()
        subject.foundations[0].cards = [
            Card(rank: .ace, suit: .spades),
            Card(rank: .two, suit: .spades),
            Card(rank: .three, suit: .spades),
        ]
        await subject.receive(.animate([], duration: 0.05))
        let destination = try #require(subject.foundations[0] as? MockCardView)
        #expect(destination.methodsCalled.isEmpty)
    }

    @Test("receive confetti: sets confetti, adds emitter, sets cancellable task")
    func confetti() async {
        subject.loadViewIfNeeded()
        Task {
            await subject.receive(.confetti)
        }
        await #while(subject.confetti == nil)
        #expect(subject.view.layer.sublayers?.compactMap { $0 as? CAEmitterLayer }.count == 1)
        #expect(subject.confettiTask != nil)
        #expect(subject.confettiTime == 10)
        subject.confettiTask?.cancel()
    }

    @Test("receive confetti: if not cancelled, cancels after `confettiTime`")
    func confettiExpires() async {
        subject.loadViewIfNeeded()
        subject.confettiTime = 0.2
        Task {
            await subject.receive(.confetti)
        }
        await #while(subject.confetti == nil)
        #expect(subject.confetti != nil)
        await #while(subject.confetti != nil)
        #expect(subject.confetti == nil)
        #expect(subject.view.layer.sublayers?.compactMap { $0 as? CAEmitterLayer }.count == 0)
        #expect(subject.confettiTask?.isCancelled == true)
    }

    @Test("every message to processor removes confetti if present")
    func confettiRemovedWhenProcessorMessage() async {
        subject.loadViewIfNeeded()
        do {
            Task {
                await subject.receive(.confetti)
            }
            await #while(subject.confetti == nil)
            subject.doDeal()
            #expect(subject.confetti == nil)
            #expect(subject.view.layer.sublayers?.compactMap { $0 as? CAEmitterLayer }.count == 0)
            #expect(subject.confettiTask?.isCancelled == true)
        }
        try? await Task.sleep(for: .seconds(0.1))
        do {
            Task {
                await subject.receive(.confetti)
            }
            await #while(subject.confetti == nil)
            subject.doUndo()
            #expect(subject.confetti == nil)
            #expect(subject.view.layer.sublayers?.compactMap { $0 as? CAEmitterLayer }.count == 0)
            #expect(subject.confettiTask?.isCancelled == true)
        }
        try? await Task.sleep(for: .seconds(0.1))
        do {
            Task {
                await subject.receive(.confetti)
            }
            await #while(subject.confetti == nil)
            subject.doRedo()
            #expect(subject.confetti == nil)
            #expect(subject.view.layer.sublayers?.compactMap { $0 as? CAEmitterLayer }.count == 0)
            #expect(subject.confettiTask?.isCancelled == true)
        }
        try? await Task.sleep(for: .seconds(0.1))
        do {
            Task {
                await subject.receive(.confetti)
            }
            await #while(subject.confetti == nil)
            subject.doUndoAll()
            #expect(subject.confetti == nil)
            #expect(subject.view.layer.sublayers?.compactMap { $0 as? CAEmitterLayer }.count == 0)
            #expect(subject.confettiTask?.isCancelled == true)
        }
        try? await Task.sleep(for: .seconds(0.1))
        do {
            Task {
                await subject.receive(.confetti)
            }
            await #while(subject.confetti == nil)
            subject.doRedoAll()
            #expect(subject.confetti == nil)
            #expect(subject.view.layer.sublayers?.compactMap { $0 as? CAEmitterLayer }.count == 0)
            #expect(subject.confettiTask?.isCancelled == true)
        }
        try? await Task.sleep(for: .seconds(0.1))
        do {
            Task {
                await subject.receive(.confetti)
            }
            await #while(subject.confetti == nil)
            subject.singleTap()
            #expect(subject.confetti == nil)
            #expect(subject.view.layer.sublayers?.compactMap { $0 as? CAEmitterLayer }.count == 0)
            #expect(subject.confettiTask?.isCancelled == true)
        }
        try? await Task.sleep(for: .seconds(0.1))
        do {
            Task {
                await subject.receive(.confetti)
            }
            await #while(subject.confetti == nil)
            subject.doubleTap()
            #expect(subject.confetti == nil)
            #expect(subject.view.layer.sublayers?.compactMap { $0 as? CAEmitterLayer }.count == 0)
            #expect(subject.confettiTask?.isCancelled == true)
        }
        try? await Task.sleep(for: .seconds(0.1))
        do {
            Task {
                await subject.receive(.confetti)
            }
            await #while(subject.confetti == nil)
            subject.twoFingerTap()
            #expect(subject.confetti == nil)
            #expect(subject.view.layer.sublayers?.compactMap { $0 as? CAEmitterLayer }.count == 0)
            #expect(subject.confettiTask?.isCancelled == true)
        }
    }

    @Test("receive removeConfetti: removes confetti if present")
    func removeConfetti() async {
        Task {
            await subject.receive(.confetti)
        }
        await #while(subject.confetti == nil)
        await subject.receive(.removeConfetti)
        #expect(subject.confetti == nil)
        #expect(subject.view.layer.sublayers?.compactMap { $0 as? CAEmitterLayer }.count == 0)
        #expect(subject.confettiTask?.isCancelled == true)
    }

    @Test("receive tint: calls tintCard -1 for foundations and freeCells, internalIndex for columns")
    func tint() async throws {
        subject.viewWillLayoutSubviews()
        let tintees: [LocationAndCard] = [
            LocationAndCard(location: Location(category: .foundation, index: 0), internalIndex: 5, card: Card(rank: .ten, suit: .hearts)),
            LocationAndCard(location: Location(category: .freeCell, index: 0), internalIndex: 5, card: Card(rank: .ten, suit: .hearts)),
            LocationAndCard(location: Location(category: .column, index: 0), internalIndex: 5, card: Card(rank: .ten, suit: .hearts)),
        ]
        await subject.receive(.tint(tintees))
        let foundationCard = try #require(subject.foundations[0] as? MockCardView)
        #expect(foundationCard.methodsCalled == ["tintCard(_:)"])
        #expect(foundationCard.tintCardIndex == -1)
        let freeCellCard = try #require(subject.freeCells[0] as? MockCardView)
        #expect(freeCellCard.methodsCalled == ["tintCard(_:)"])
        #expect(freeCellCard.tintCardIndex == -1)
        let columnCard = try #require(subject.columns[0] as? MockCardView)
        #expect(columnCard.methodsCalled == ["tintCard(_:)"])
        #expect(columnCard.tintCardIndex == 5)
    }

    @Test("receive tintsOff: calls removeTintLayers on all cards")
    func tintsOff() async throws {
        subject.viewWillLayoutSubviews()
        await subject.receive(.tintsOff)
        let foundationCard = try #require(subject.foundations[0] as? MockCardView)
        #expect(foundationCard.methodsCalled == ["removeTintLayers()"])
        let freeCellCard = try #require(subject.freeCells[0] as? MockCardView)
        #expect(freeCellCard.methodsCalled == ["removeTintLayers()"])
        let columnCard = try #require(subject.columns[0] as? MockCardView)
        #expect(columnCard.methodsCalled == ["removeTintLayers()"])
    }

    @Test("receive updateStopwatch: sets label with formatted string")
    func updateStopwatch() async {
        subject.loadViewIfNeeded()
        await subject.receive(.updateStopwatch(1))
        #expect(subject.timerLabel.text == "00:00:01")
    }

    @Test("viewWillTransition: removes all card views, calls debouncer")
    func viewWillTransition() async {
        subject.viewWillLayoutSubviews()
        await #while(processor.thingsReceived.isEmpty)
        let cardView = subject.foundations[0]
        subject.view.addSubview(cardView)
        let viewController = UIViewController()
        makeWindow(viewController: viewController)
        let presentedViewController = MyViewController()
        // sneaky trick to allow us to call `viewWillTransition`
        presentedViewController.operation = { coordinator in
            subject.viewWillTransition(to: CGSize(width: 400, height: 400), with: coordinator)
        }
        // okay, that was prep, this is the test!
        viewController.present(presentedViewController, animated: false)
        await #while(debouncer.methodsCalled.isEmpty)
        // and our view controller calls `subject.viewWillTransition` which is what we want to test!
        #expect(subject.foundations.isEmpty)
        #expect(subject.freeCells.isEmpty)
        #expect(subject.columns.isEmpty)
        #expect(cardView.superview == nil)
        #expect(debouncer.methodsCalled == ["eventOccurred()"])
    }

    @Test("debounced: basically just like viewDidLayoutSubviews, with resized action at end")
    func debounced() async throws {
        sizer.sizeToReturn = CGSize(width: 50, height: 100)
        subject.view.bounds.size.width = 400
        await subject.debounced()
        #expect(sizer.methodsCalled == ["cardSize(boardWidth:)"])
        #expect(sizer.boardWidth == 400)
        #expect(CardView.baseSize == CGSize(width: 50, height: 100))
        #expect(constructor.methodsCalled == ["constructInterface(in:)"])
        #expect(constructor.view === subject.view)
        let foundation = try #require(subject.foundations.first)
        #expect(foundation.location.category == .foundation)
        let freeCell = try #require(subject.freeCells.first)
        #expect(freeCell.location.category == .freeCell)
        let column = try #require(subject.columns.first)
        #expect(column.location.category == .column)
        #expect(processor.thingsReceived == [.resized])
    }
}

/// Sneaky trick to give us a workable transition coordinator.
private final class MyViewController: UIViewController {
    var operation: ((any UIViewControllerTransitionCoordinator) -> Void)?
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        if let operation, let transitionCoordinator {
            operation(transitionCoordinator)
        }
    }
}
