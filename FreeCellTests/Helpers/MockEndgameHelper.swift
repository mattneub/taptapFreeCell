@testable import TTFreeCell
import Foundation

final class MockEndgameHelper: EndgameHelperType {
    var methodsCalled = [String]()
    var index: Int?
    var layoutPassedIn: Layout?
    var layoutToReturn = Layout()

    func autoplay(layout: inout Layout) {
        methodsCalled.append(#function)
        layoutPassedIn = layout
        layout = layoutToReturn
    }

    func splat(layout: inout Layout, index: Int) {
        methodsCalled.append(#function)
        self.index = index
        layoutPassedIn = layout
        layout = layoutToReturn
    }

    func shift(layout: inout Layout, index: Int) {
        methodsCalled.append(#function)
        self.index = index
        layoutPassedIn = layout
        layout = layoutToReturn
    }
}
