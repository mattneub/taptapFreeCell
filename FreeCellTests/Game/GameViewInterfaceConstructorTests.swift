@testable import FreeCell
import Testing
import UIKit

struct GameViewInterfaceConstructorTests {
    @Test("interface is correctly constructed and card views are correctly returned")
    func construct() throws {
        CardView.baseSize = CGSize(width: 35, height: 60)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        view.backgroundColor = .green
        let result = GameViewInterfaceConstructor().constructInterface(in: view)
        #expect(view.subviews(ofType: CardView.self).count == 16)
        #expect(result.count == 3)
        let foundations = result[0]
        #expect(foundations.count == 4)
        #expect(foundations.allSatisfy { $0.category == .foundation })
        #expect(foundations.map { $0.index } == [0, 1, 2, 3])
        let freeCells = result[1]
        #expect(freeCells.count == 4)
        #expect(freeCells.allSatisfy { $0.category == .freeCell })
        #expect(freeCells.map { $0.index } == [0, 1, 2, 3])
        let columns = result[2]
        #expect(columns.count == 8)
        #expect(columns.allSatisfy { $0.category == .column })
        #expect(columns.map { $0.index } == [0, 1, 2, 3, 4, 5, 6, 7])
    }
}
