@testable import FreeCell
import UIKit

final class MockGameViewInterfaceConstructor: GameViewInterfaceConstructorType {
    var methodsCalled = [String]()
    var view: UIView?
    var cardViews: [[CardView]] = [
        [MockCardView(location: Location(category: .foundation, index: 0))],
        [MockCardView(location: Location(category: .freeCell, index: 0))],
        [MockCardView(location: Location(category: .column, index: 0))]
    ]

    func constructInterface(in view: UIView) -> [[CardView]] {
        methodsCalled.append(#function)
        self.view = view
        return cardViews
    }
}
