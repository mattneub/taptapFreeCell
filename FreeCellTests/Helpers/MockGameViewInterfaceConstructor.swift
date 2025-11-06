@testable import FreeCell
import UIKit

final class MockGameViewInterfaceConstructor: GameViewInterfaceConstructorType {
    var methodsCalled = [String]()
    var view: UIView?

    func constructInterface(in view: UIView) {
        methodsCalled.append(#function)
        self.view = view
    }

}
