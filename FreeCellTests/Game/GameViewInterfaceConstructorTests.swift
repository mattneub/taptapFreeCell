@testable import FreeCell
import Testing
import UIKit
import SnapshotTesting

struct GameViewInterfaceConstructorTests {
    @Test("interface is correctly constructed")
    func construct() {
        CardView.baseSize = CGSize(width: 35, height: 60)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        view.backgroundColor = .green
        GameViewInterfaceConstructor().constructInterface(in: view)
        #expect(view.subviews(ofType: CardView.self).count == 16)
        let viewController = UIViewController()
        makeWindow(viewController: viewController)
        viewController.view.addSubview(view)
        viewController.view.layoutIfNeeded()
        assertSnapshot(of: view, as: .image)
    }
}
