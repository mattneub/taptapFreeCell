@testable import FreeCell
import UIKit

final class MockGameViewInterfaceConstructor: GameViewInterfaceConstructorType {
    var methodsCalled = [String]()
    var view: UIView?

    func constructInterface(in view: UIView) -> [[CardView]] {
        methodsCalled.append(#function)
        self.view = view
        return [
            [CardView(category: .foundation(.spades), index: 0)],
            [CardView(category: .freeCell, index: 0)],
            [CardView(category: .column, index: 0)]
        ]
    }

}
