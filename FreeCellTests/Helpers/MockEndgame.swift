@testable import TTFreeCell
import Foundation

final class MockEndgame: EndgameType {
    var methodsCalled = [String]()
    var layout: Layout?
    var layoutsToReturn = [Layout]()

    func evaluate(_ layout: Layout) -> [Layout] {
        methodsCalled.append(#function)
        self.layout = layout
        return layoutsToReturn
    }

}
