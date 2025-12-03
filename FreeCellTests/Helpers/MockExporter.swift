@testable import TTFreeCell
import Foundation

final class MockExporter: ExporterType {
    var methodsCalled = [String]()
    var layout: Layout?
    var moves: [String]?
    var messageToReturn = ""

    func messageText(layout: Layout, moves: [String]?) -> String {
        methodsCalled.append(#function)
        self.layout = layout
        self.moves = moves
        return messageToReturn
    }
}
