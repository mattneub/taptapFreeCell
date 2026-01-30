@testable import TTFreeCell
import Foundation

final class MockEndgameHelper: EndgameHelperType {
    var methodsCalled = [String]()
    var indexes = [Int]()
    var layoutsToReturn = [Layout()]

    func autoplay(layout: inout Layout) {
        methodsCalled.append(#function)
        layout = layoutsToReturn.popLast() ?? Layout()
    }

    func splat(layout: inout Layout, index: Int) {
        methodsCalled.append(#function)
        indexes.append(index)
        layout = layoutsToReturn.popLast() ?? Layout()
    }

    func shift(layout: inout Layout, index: Int) {
        methodsCalled.append(#function)
        indexes.append(index)
        layout = layoutsToReturn.popLast() ?? Layout()
    }
}
