@testable import TTFreeCell
import Foundation

final class MockEndgameExtraPly: EndgameExtraPlyType {
    var methodsCalled = [String]()
    var layouts = [Layout]()
    var layoutsToReturn: [Layout]?

    func doExtraPly(_ layouts: [Layout]) -> [Layout]? {
        methodsCalled.append(#function)
        self.layouts = layouts
        return layoutsToReturn
    }

}
