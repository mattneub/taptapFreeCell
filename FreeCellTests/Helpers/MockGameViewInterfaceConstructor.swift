@testable import TTFreeCell
import UIKit

final class MockGameViewInterfaceConstructor: GameViewInterfaceConstructorType {
    var methodsCalled = [String]()
    var view: UIView?
    var foundationTapper: UIView?
    var foundations = [CardView]()
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

    func configureFoundationTapperConstraints(
        in view: UIView,
        foundationTapper: UIView,
        foundations: [CardView]
    ) {
        methodsCalled.append(#function)
        self.view = view
        self.foundationTapper = foundationTapper
        self.foundations = foundations
    }

}
