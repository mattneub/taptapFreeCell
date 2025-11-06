@testable import FreeCell
import UIKit

final class MockGameViewCardSizer: GameViewCardSizerType {
    var methodsCalled = [String]()
    var sizeToReturn = CGSize.zero
    var boardWidth: CGFloat?

    func cardSize(boardWidth: CGFloat) -> CGSize {
        methodsCalled.append(#function)
        self.boardWidth = boardWidth
        return sizeToReturn
    }

}
