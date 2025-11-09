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

    @Test("viewDidLoad: configures bar button items, adds image view, tap gesture recognizer")
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
        let tapper = try #require(subject.view.gestureRecognizers?.first as? MyTapGestureRecognizer)
        #expect(tapper.numberOfTapsRequired == 2)
        #expect(tapper.target === subject)
        #expect(tapper.action == #selector(subject.doubleTap))
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
        #expect(foundation.category == .foundation(.spades))
        let freeCell = try #require(subject.freeCells.first)
        #expect(freeCell.category == .freeCell)
        let column = try #require(subject.columns.first)
        #expect(column.category == .column)
        sizer.methodsCalled = []
        constructor.methodsCalled = []
        subject.viewWillLayoutSubviews()
        #expect(sizer.methodsCalled.isEmpty)
        #expect(constructor.methodsCalled.isEmpty)
    }

    @Test("view will layout: configures all card views as empty")
    func viewWillLayoutRedraw() async throws {
        sizer.sizeToReturn = CGSize(width: 50, height: 100)
        subject.view.bounds.size.width = 400
        subject.gameViewInterfaceConstructor = GameViewInterfaceConstructor() // real layout
        subject.viewWillLayoutSubviews()
        await #while(subject.columns[7].emptyLayer == nil)
        #expect(subject.foundations.count == 4)
        #expect(subject.freeCells.count == 4)
        #expect(subject.columns.count == 8)
        let allCards = subject.view.subviews(ofType: CardView.self)
        #expect(allCards.count == 16)
        #expect(allCards.allSatisfy { $0.cards.isEmpty })
        #expect(allCards.allSatisfy { $0.emptyLayer?.superlayer != nil })
    }

    @Test("present: distributes state layout cards into card views, tells them to redraw")
    func present() async {
        sizer.sizeToReturn = CGSize(width: 50, height: 100)
        subject.view.bounds.size.width = 400
        subject.gameViewInterfaceConstructor = GameViewInterfaceConstructor() // real layout
        subject.viewWillLayoutSubviews()
        await #while(subject.columns[7].emptyLayer == nil)
        var layout = Layout()
        layout.foundations[layout.indexOfFoundation(for: .hearts)].cards = [.init(rank: .ace, suit: .hearts)]
        layout.freeCells[3].card = .init(rank: .king, suit: .hearts)
        layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
        layout.columns[6].cards = [
            .init(rank: .jack, suit: .hearts),
            .init(rank: .ten, suit: .clubs)
        ]
        // that was prep, here comes the test
        await subject.present(.init(layout: layout, sequences: false))
        // what we want to know is not just that the cards were dealt out but that they _appear_
        #expect(subject.foundations[0].cards == [])
        #expect(subject.foundations[0].emptyLayer?.superlayer != nil)
        #expect(subject.foundations[1].cards == [.init(rank: .ace, suit: .hearts)])
        #expect((subject.foundations[1].layer.sublayers?[0] as? CardLayer)?.card == .init(rank: .ace, suit: .hearts))
        #expect(subject.foundations[2].cards == [])
        #expect(subject.foundations[2].emptyLayer?.superlayer != nil)
        #expect(subject.foundations[3].cards == [])
        #expect(subject.foundations[3].emptyLayer?.superlayer != nil)
        #expect(subject.freeCells[0].cards == [])
        #expect(subject.freeCells[0].emptyLayer?.superlayer != nil)
        #expect(subject.freeCells[1].cards == [])
        #expect(subject.freeCells[1].emptyLayer?.superlayer != nil)
        #expect(subject.freeCells[2].cards == [])
        #expect(subject.freeCells[2].emptyLayer?.superlayer != nil)
        #expect(subject.freeCells[3].cards == [.init(rank: .king, suit: .hearts)])
        #expect((subject.freeCells[3].layer.sublayers?[0] as? CardLayer)?.card == .init(rank: .king, suit: .hearts))
        #expect(subject.columns[0].cards == [.init(rank: .queen, suit: .hearts)])
        #expect((subject.columns[0].layer.sublayers?[0] as? CardLayer)?.card == .init(rank: .queen, suit: .hearts))
        #expect((subject.columns[0].layer.sublayers?.count == 1)) // and that's all there are
        #expect(subject.columns[1].cards == [])
        #expect(subject.columns[1].emptyLayer?.superlayer != nil)
        #expect(subject.columns[2].cards == [])
        #expect(subject.columns[2].emptyLayer?.superlayer != nil)
        #expect(subject.columns[3].cards == [])
        #expect(subject.columns[3].emptyLayer?.superlayer != nil)
        #expect(subject.columns[4].cards == [])
        #expect(subject.columns[4].emptyLayer?.superlayer != nil)
        #expect(subject.columns[5].cards == [])
        #expect(subject.columns[5].emptyLayer?.superlayer != nil)
        #expect(subject.columns[6].cards == [
            .init(rank: .jack, suit: .hearts),
            .init(rank: .ten, suit: .clubs)
        ])
        #expect((subject.columns[6].layer.sublayers?[0] as? CardLayer)?.card == .init(rank: .jack, suit: .hearts))
        #expect((subject.columns[6].layer.sublayers?[1] as? CardLayer)?.card == .init(rank: .ten, suit: .clubs))
        #expect((subject.columns[6].layer.sublayers?.count == 2)) // and that's all there are
        #expect(subject.columns[7].cards == [])
        #expect(subject.columns[7].emptyLayer?.superlayer != nil)
    }

    @Test("present: distributes state layout cards into card views, tells them to redraw with borders")
    func presentBorders() async throws {
        sizer.sizeToReturn = CGSize(width: 50, height: 100)
        subject.view.bounds.size.width = 400
        subject.gameViewInterfaceConstructor = GameViewInterfaceConstructor() // real layout
        subject.viewWillLayoutSubviews()
        await #while(subject.columns[7].emptyLayer == nil)
        var layout = Layout()
        layout.foundations[layout.indexOfFoundation(for: .hearts)].cards = [.init(rank: .ace, suit: .hearts)]
        layout.freeCells[3].card = .init(rank: .king, suit: .hearts)
        layout.columns[0].cards = [.init(rank: .queen, suit: .hearts)]
        layout.columns[6].cards = [
            .init(rank: .jack, suit: .hearts),
            .init(rank: .ten, suit: .clubs)
        ]
        // that was prep, here comes the test
        await subject.present(.init(layout: layout, sequences: true)) // *
        // what we want to know is not just that the cards were dealt out but that they _appear_
        #expect(subject.foundations[0].cards == [])
        #expect(subject.foundations[0].emptyLayer?.superlayer != nil)
        #expect(subject.foundations[1].cards == [.init(rank: .ace, suit: .hearts)])
        #expect((subject.foundations[1].layer.sublayers?[0] as? CardLayer)?.card == .init(rank: .ace, suit: .hearts))
        #expect(subject.foundations[2].cards == [])
        #expect(subject.foundations[2].emptyLayer?.superlayer != nil)
        #expect(subject.foundations[3].cards == [])
        #expect(subject.foundations[3].emptyLayer?.superlayer != nil)
        #expect(subject.freeCells[0].cards == [])
        #expect(subject.freeCells[0].emptyLayer?.superlayer != nil)
        #expect(subject.freeCells[1].cards == [])
        #expect(subject.freeCells[1].emptyLayer?.superlayer != nil)
        #expect(subject.freeCells[2].cards == [])
        #expect(subject.freeCells[2].emptyLayer?.superlayer != nil)
        #expect(subject.freeCells[3].cards == [.init(rank: .king, suit: .hearts)])
        #expect((subject.freeCells[3].layer.sublayers?[0] as? CardLayer)?.card == .init(rank: .king, suit: .hearts))
        #expect(subject.columns[0].cards == [.init(rank: .queen, suit: .hearts)])
        #expect((subject.columns[0].layer.sublayers?[0] as? CardLayer)?.card == .init(rank: .queen, suit: .hearts))
        #expect((subject.columns[0].layer.sublayers?.count == 2)) // *
        let borderLayer = try #require(subject.columns[0].layer.sublayers?.last)
        #expect(borderLayer.borderColor == UIColor.blue.cgColor)
        #expect(subject.columns[1].cards == [])
        #expect(subject.columns[1].emptyLayer?.superlayer != nil)
        #expect(subject.columns[2].cards == [])
        #expect(subject.columns[2].emptyLayer?.superlayer != nil)
        #expect(subject.columns[3].cards == [])
        #expect(subject.columns[3].emptyLayer?.superlayer != nil)
        #expect(subject.columns[4].cards == [])
        #expect(subject.columns[4].emptyLayer?.superlayer != nil)
        #expect(subject.columns[5].cards == [])
        #expect(subject.columns[5].emptyLayer?.superlayer != nil)
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
        #expect(subject.columns[7].emptyLayer?.superlayer != nil)
    }

    @Test("doDeal: sends deal")
    func doDeal() async {
        subject.doDeal()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.deal])
    }

    @Test("doubleTap: sends autoplay")
    func doubleTap() async {
        subject.doubleTap()
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.autoplay])
    }
}
