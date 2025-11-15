@testable import FreeCell
import Testing
import UIKit
import WaitWhile

struct GameViewControllerTests {
    let subject = GameViewController()
    let sizer = MockGameViewCardSizer()
    let constructor = MockGameViewInterfaceConstructor()
    let builder = MockGameViewMenuBuilder()
    let processor = MockReceiver<GameAction>()

    init() {
        subject.gameViewCardSizer = sizer
        subject.gameViewInterfaceConstructor = constructor
        subject.gameViewMenuBuilder = builder
        subject.processor = processor
    }

    @Test("timerLabel is correctly constructed")
    func timerLabel() {
        let label = subject.timerLabel
        #expect(label.text == "00:00:00")
        #expect(label.font == UIFont(name: "ArialRoundedMTBold", size: 16))
        #expect(label.textAlignment == .center)
        #expect(label.translatesAutoresizingMaskIntoConstraints == false)
    }

    @Test("timerGlass is correctly constructed")
    func timerGlass() {
        let glass = subject.timerGlass
        #expect(glass.cornerConfiguration == .capsule())
        #expect(glass.bounds.size.width == 82)
        #expect(glass.bounds.size.height == 44)
        let label = subject.timerLabel
        #expect(label.isDescendant(of: glass))
        glass.layoutIfNeeded()
        #expect(label.frame.midX.rounded() == glass.bounds.midX)
        #expect(label.frame.midY.rounded() == glass.bounds.midY)
    }

    @Test("viewDidLoad: configures bar button items, adds image view, tap gesture recognizers")
    func viewDidLoad() throws {
        subject.loadViewIfNeeded()
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
        #expect(builder.methodsCalled == ["buildMenu()"])
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
        #expect(subject.navigationItem.titleView === subject.timerGlass)
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

    @Test("view will layout: first time only, calls card sizer, interface constructor")
    func viewWillLayout() throws {
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
        sizer.methodsCalled = []
        constructor.methodsCalled = []
        subject.viewWillLayoutSubviews()
        #expect(sizer.methodsCalled.isEmpty)
        #expect(constructor.methodsCalled.isEmpty)
    }

    @Test("view will layout: configures all card views as empty, sets processor; card views category and index are right")
    func viewWillLayoutRedraw() async throws {
        sizer.sizeToReturn = CGSize(width: 50, height: 100)
        subject.view.bounds.size.width = 400
        subject.gameViewInterfaceConstructor = GameViewInterfaceConstructor() // real layout
        subject.viewWillLayoutSubviews()
        #expect(subject.foundations.count == 4)
        #expect(subject.foundations.enumerated().allSatisfy { offset, foundation in
            foundation.location.index == offset &&
            foundation.location.category == .foundation
        })
        #expect(subject.freeCells.count == 4)
        #expect(subject.freeCells.enumerated().allSatisfy { offset, freeCell in
            freeCell.location.index == offset &&
            freeCell.location.category == .freeCell
        })
        #expect(subject.columns.count == 8)
        #expect(subject.columns.enumerated().allSatisfy { offset, column in
            column.location.index == offset &&
            column.location.category == .column
        })
        let allCards = subject.view.subviews(ofType: CardView.self)
        #expect(allCards.count == 16)
        #expect(allCards.allSatisfy { $0.cards.isEmpty })
        await #while(!(allCards.allSatisfy { $0.processor === processor }))
        #expect(allCards.allSatisfy { $0.processor === processor })
        #expect(allCards.allSatisfy { $0.layer.sublayers?.first != nil })
        #expect(allCards.allSatisfy { $0.alpha == 0.5 })
    }

    @Test("present: distributes state layout cards into card views, tells them to redraw")
    func present() async {
        sizer.sizeToReturn = CGSize(width: 50, height: 100)
        subject.view.bounds.size.width = 400
        subject.gameViewInterfaceConstructor = GameViewInterfaceConstructor() // real layout
        subject.viewWillLayoutSubviews()
        var layout = Layout()
        layout.foundations[layout.indexOfFoundation(for: .hearts)].cards = [.init(rank: .ace, suit: .hearts)]
        layout.freeCells[3].cards = [.init(rank: .king, suit: .hearts)]
        layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
        layout.columns[6].cards = [
            .init(rank: .jack, suit: .hearts),
            .init(rank: .ten, suit: .clubs)
        ]
        // that was prep, here comes the test
        await subject.present(.init(layout: layout, sequences: false))
        // what we want to know is not just that the cards were dealt out but that they _appear_
        #expect(subject.foundations[0].cards == [])
        #expect(subject.foundations[1].cards == [.init(rank: .ace, suit: .hearts)])
        #expect((subject.foundations[1].layer.sublayers?[0] as? CardLayer)?.card == .init(rank: .ace, suit: .hearts))
        #expect(subject.foundations[2].cards == [])
        #expect(subject.foundations[3].cards == [])
        #expect(subject.freeCells[0].cards == [])
        #expect(subject.freeCells[1].cards == [])
        #expect(subject.freeCells[2].cards == [])
        #expect(subject.freeCells[3].cards == [.init(rank: .king, suit: .hearts)])
        #expect((subject.freeCells[3].layer.sublayers?[0] as? CardLayer)?.card == .init(rank: .king, suit: .hearts))
        #expect(subject.columns[0].cards == [.init(rank: .queen, suit: .hearts)])
        #expect((subject.columns[0].layer.sublayers?[0] as? CardLayer)?.card == .init(rank: .queen, suit: .hearts))
        #expect((subject.columns[0].layer.sublayers?.count == 1)) // and that's all there are
        #expect(subject.columns[1].cards == [])
        #expect(subject.columns[2].cards == [])
        #expect(subject.columns[3].cards == [])
        #expect(subject.columns[4].cards == [])
        #expect(subject.columns[5].cards == [])
        #expect(subject.columns[6].cards == [
            .init(rank: .jack, suit: .hearts),
            .init(rank: .ten, suit: .clubs)
        ])
        #expect((subject.columns[6].layer.sublayers?[0] as? CardLayer)?.card == .init(rank: .jack, suit: .hearts))
        #expect((subject.columns[6].layer.sublayers?[1] as? CardLayer)?.card == .init(rank: .ten, suit: .clubs))
        #expect((subject.columns[6].layer.sublayers?.count == 2)) // and that's all there are
        #expect(subject.columns[7].cards == [])
    }

    @Test("present: distributes state layout cards into card views, tells them to redraw with borders")
    func presentBorders() async throws {
        sizer.sizeToReturn = CGSize(width: 50, height: 100)
        subject.view.bounds.size.width = 400
        subject.gameViewInterfaceConstructor = GameViewInterfaceConstructor() // real layout
        subject.viewWillLayoutSubviews()
        var layout = Layout()
        layout.foundations[layout.indexOfFoundation(for: .hearts)].cards = [.init(rank: .ace, suit: .hearts)]
        layout.freeCells[3].cards = [.init(rank: .king, suit: .hearts)]
        layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
        layout.columns[6].cards = [
            .init(rank: .jack, suit: .hearts),
            .init(rank: .ten, suit: .clubs)
        ]
        // that was prep, here comes the test
        await subject.present(.init(layout: layout, sequences: true)) // *
        // what we want to know is not just that the cards were dealt out but that they _appear_
        #expect(subject.foundations[0].cards == [])
        #expect(subject.foundations[1].cards == [.init(rank: .ace, suit: .hearts)])
        #expect((subject.foundations[1].layer.sublayers?[0] as? CardLayer)?.card == .init(rank: .ace, suit: .hearts))
        #expect(subject.foundations[2].cards == [])
        #expect(subject.foundations[3].cards == [])
        #expect(subject.freeCells[0].cards == [])
        #expect(subject.freeCells[1].cards == [])
        #expect(subject.freeCells[2].cards == [])
        #expect(subject.freeCells[3].cards == [.init(rank: .king, suit: .hearts)])
        #expect((subject.freeCells[3].layer.sublayers?[0] as? CardLayer)?.card == .init(rank: .king, suit: .hearts))
        #expect(subject.columns[0].cards == [.init(rank: .queen, suit: .hearts)])
        #expect((subject.columns[0].layer.sublayers?[0] as? CardLayer)?.card == .init(rank: .queen, suit: .hearts))
        #expect((subject.columns[0].layer.sublayers?.count == 2)) // *
        let borderLayer = try #require(subject.columns[0].layer.sublayers?.last)
        #expect(borderLayer.borderColor == UIColor.blue.cgColor)
        #expect(subject.columns[1].cards == [])
        #expect(subject.columns[2].cards == [])
        #expect(subject.columns[3].cards == [])
        #expect(subject.columns[4].cards == [])
        #expect(subject.columns[5].cards == [])
        #expect(subject.columns[6].cards == [
            .init(rank: .jack, suit: .hearts),
            .init(rank: .ten, suit: .clubs)
        ])
        #expect((subject.columns[6].layer.sublayers?[0] as? CardLayer)?.card == .init(rank: .jack, suit: .hearts))
        #expect((subject.columns[6].layer.sublayers?[1] as? CardLayer)?.card == .init(rank: .ten, suit: .clubs))
        #expect((subject.columns[6].layer.sublayers?.count == 3)) // *
        let borderLayer2 = try #require(subject.columns[6].layer.sublayers?.last)
        #expect(borderLayer2.borderColor == UIColor.blue.cgColor)
        #expect(subject.columns[7].cards == [])
    }

    @Test("present: if highlightOn false, removes and nilifies highlightLayer")
    func presentHighlightOnFalse() async {
        subject.gameViewInterfaceConstructor = GameViewInterfaceConstructor() // real layout
        subject.viewWillLayoutSubviews()
        let layer = CALayer()
        subject.view.layer.addSublayer(layer)
        subject.highlightLayer = layer
        await subject.present(GameState())
        #expect(subject.highlightLayer == nil)
        #expect(layer.superlayer == nil)
    }

    @Test("present: if highlightOn true, adds and configures highlightLayer")
    func presentHighlightOnTrue() async throws {
        subject.gameViewInterfaceConstructor = GameViewInterfaceConstructor() // real layout
        subject.viewWillLayoutSubviews()
        await subject.present(GameState(firstTapLocation: .init(category: .column, index: 0)))
        let layer = try #require(subject.highlightLayer)
        #expect(layer.superlayer === subject.columns[0].layer.superlayer)
        #expect(layer.frame == subject.columns[0].layer.frame)
        #expect(layer.zPosition == 2000)
        // could check transform etc. but not worth worrying about it
    }

    @Test("present: sets card view enablements")
    func presentEnablements() async throws {
        subject.gameViewInterfaceConstructor = GameViewInterfaceConstructor() // real layout
        subject.viewWillLayoutSubviews()
        let allCardViews = subject.view.subviews.compactMap { $0 as? CardView }
        allCardViews.forEach { $0.cards = [.init(rank: .two, suit: .clubs)] }
        allCardViews.forEach { $0.setEnablement(.enabled) }
        #expect(allCardViews.allSatisfy { $0.alpha == 1 })
        var state = GameState()
        state.enablements = state.baseEnablements
        await subject.present(state)
        #expect(allCardViews.allSatisfy { $0.alpha == 0.5 })
    }

    @Test("doDeal: sends deal")
    func doDeal() async {
        subject.doDeal()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.deal])
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
}
