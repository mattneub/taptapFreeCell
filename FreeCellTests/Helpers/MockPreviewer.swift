@testable import TTFreeCell
import UIKit

final class MockPreviewer: PreviewerType {
    var methodsCalled = [String]()
    var stat: Stat?
    var viewControllerToReturn: UIViewController?

    func viewController(for stat: Stat) async -> UIViewController? {
        methodsCalled.append(#function)
        self.stat = stat
        return viewControllerToReturn
    }
}
