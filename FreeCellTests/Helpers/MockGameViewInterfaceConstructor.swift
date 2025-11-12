@testable import FreeCell
import UIKit

final class MockGameViewInterfaceConstructor: GameViewInterfaceConstructorType {
    var methodsCalled = [String]()
    var view: UIView?

    func constructInterface(in view: UIView) -> [[CardView]] {
        methodsCalled.append(#function)
        self.view = view
        return [
            [CardView(location: .init(category: .foundation, index: 0))],
            [CardView(location: .init(category: .freeCell, index: 0))],
            [CardView(location: .init(category: .column, index: 0))]
        ]
    }

}
