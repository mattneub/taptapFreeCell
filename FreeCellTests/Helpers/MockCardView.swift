@testable import FreeCell
import UIKit

final class MockCardView: CardView {
    var methodsCalled = [String]()
    var tintCardIndex: Int?

    override func redraw(movableCount: Int = 0) async {
        // do nothing
    }

    override func tintCard(_ index: Int) {
        methodsCalled.append(#function)
        tintCardIndex = index
    }

    override func removeTintLayers() {
        methodsCalled.append(#function)
    }
}
