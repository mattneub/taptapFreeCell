@testable import TTFreeCell
import UIKit

final class MockAnimator: AnimatorType {
    var methodsCalled = [String]()
    var oldLayout: Layout?
    var newLayout: Layout?
    var oldLayouts = [Layout]()
    var newLayouts = [Layout]()
    var speed: GameState.AnimationSpeed?

    func animate(oldLayout: Layout, newLayout: Layout, speed: GameState.AnimationSpeed) async {
        methodsCalled.append(#function)
        self.oldLayout = oldLayout
        self.oldLayouts.append(oldLayout)
        self.newLayout = newLayout
        self.newLayouts.append(newLayout)
        self.speed = speed
    }
}
