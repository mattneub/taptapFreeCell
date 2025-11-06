@testable import FreeCell
import Testing
import UIKit

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

    @Test("viewDidLoad: configures bar button items, adds image view")
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
    }

    @Test("view will layout: first time only, calls card sizer, interface constructor")
    func viewWillLayout() {
        sizer.sizeToReturn = CGSize(width: 50, height: 100)
        subject.view.bounds.size.width = 400
        subject.viewWillLayoutSubviews()
        #expect(sizer.methodsCalled == ["cardSize(boardWidth:)"])
        #expect(sizer.boardWidth == 400)
        #expect(CardView.baseSize == CGSize(width: 50, height: 100))
        #expect(constructor.methodsCalled == ["constructInterface(in:)"])
        #expect(constructor.view === subject.view)
    }
}
