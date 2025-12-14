@testable import TTFreeCell
import Testing
import UIKit
import SnapshotTesting

private struct GameViewInterfaceConstructorTests {
    @Test("interface is correctly constructed and card views are correctly returned")
    func construct() throws {
        CardView.baseSize = CGSize(width: 35, height: 60)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        let result = GameViewInterfaceConstructor().constructInterface(in: view)
        #expect(view.subviews(ofType: CardView.self).count == 16)
        #expect(result.count == 3)
        let foundations = result[0]
        #expect(foundations.count == 4)
        #expect(foundations.allSatisfy { $0.location.category == .foundation })
        #expect(foundations.map { $0.location.index } == [0, 1, 2, 3])
        let freeCells = result[1]
        #expect(freeCells.count == 4)
        #expect(freeCells.allSatisfy { $0.location.category == .freeCell })
        #expect(freeCells.map { $0.location.index } == [0, 1, 2, 3])
        let columns = result[2]
        #expect(columns.count == 8)
        #expect(columns.allSatisfy { $0.location.category == .column })
        #expect(columns.map { $0.location.index } == [0, 1, 2, 3, 4, 5, 6, 7])
    }

    @Test("interface looks right")
    func gameViewAppearance() throws {
        CardView.baseSize = CGSize(width: 35, height: 60)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        view.backgroundColor = .green // artificial so we can see what we've got
        _ = GameViewInterfaceConstructor().constructInterface(in: view)
        for cardView in view.subviews(ofType: CardView.self) {
            cardView.backgroundColor = .red // ditto, we just want to see where they are
        }
        let viewController = UIViewController()
        makeWindow(viewController: viewController)
        viewController.view.addSubview(view)
        view.layoutIfNeeded()
        assertSnapshot(of: view, as: .image(size: CGSize(width: 400, height: 400)))
    }

    @Test("interface looks right when view is wide")
    func gameViewAppearanceWide() throws {
        CardView.baseSize = CGSize(width: 35, height: 60)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1000, height: 400))
        view.backgroundColor = .green // artificial so we can see what we've got
        _ = GameViewInterfaceConstructor().constructInterface(in: view)
        for cardView in view.subviews(ofType: CardView.self) {
            cardView.backgroundColor = .red // ditto, we just want to see where they are
        }
        let viewController = UIViewController()
        makeWindow(viewController: viewController)
        viewController.view.addSubview(view)
        view.layoutIfNeeded()
        // key thing here is the wide margins at both sides
        assertSnapshot(of: view, as: .image(size: CGSize(width: 1000, height: 400)))
    }
}
