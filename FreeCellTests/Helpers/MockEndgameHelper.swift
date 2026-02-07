@testable import TTFreeCell
import Foundation

final class MockEndgameHelper: EndgameHelperType {
    var methodsCalled = [String]()
    var indexes = [Int]()
    var layoutsPassedIn = [Layout]()
    var layoutsToReturn = [Layout()]

    func autoplay(layout: inout Layout) {
        methodsCalled.append(#function)
        layoutsPassedIn.append(layout)
        layout = layoutsToReturn.removeFirst()
    }

    func splat(layout: inout Layout, index: Int) {
        methodsCalled.append(#function)
        indexes.append(index)
        layoutsPassedIn.append(layout)
        layout = layoutsToReturn.removeFirst()
    }

    func shift(layout: inout Layout, index: Int) {
        methodsCalled.append(#function)
        indexes.append(index)
        layoutsPassedIn.append(layout)
        layout = layoutsToReturn.removeFirst()
    }
}
