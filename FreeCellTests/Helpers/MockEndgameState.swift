@testable import TTFreeCell
import Foundation

final class MockEndgameState: EndgameStateType {
    func nextState() -> (any EndgameStateType)? {
        return nil
    }
}
