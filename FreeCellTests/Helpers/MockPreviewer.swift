@testable import TTFreeCell
import UIKit

final class MockPreviewer: PreviewerType {
    var methodsCalled = [String]()
    var stat: Stat?
    var source: UIView?
    var viewControllerToReturn: UIViewController?

    func viewController(for stat: Stat, source: UIView?) async -> UIViewController? {
        methodsCalled.append(#function)
        self.stat = stat
        self.source = source
        return viewControllerToReturn
    }
}
