@testable import TTFreeCell
import UIKit

final class MockCardView: CardView {
    var methodsCalled = [String]()
    var tintCardIndex: Int?
    var hideCardIndex: Int?
    var movableCount: Int?
    var enablement: GameState.Enablement?

    override func redraw(movableCount: Int = 0) async {
        methodsCalled.append(#function)
        self.movableCount = movableCount
    }

    override func setEnablement(_ enablement: GameState.Enablement) {
        methodsCalled.append(#function)
        self.enablement = enablement
    }

    override func tintCard(_ index: Int) {
        methodsCalled.append(#function)
        tintCardIndex = index
    }

    override func removeTintLayers() {
        methodsCalled.append(#function)
    }

    override func hideCard(at index: Int) {
        methodsCalled.append(#function)
        hideCardIndex = index
    }

    override func showCards() {
        methodsCalled.append(#function)
    }

    override func hideBorder() {
        methodsCalled.append(#function)
    }

    override func showBorder() {
        methodsCalled.append(#function)
    }
}
