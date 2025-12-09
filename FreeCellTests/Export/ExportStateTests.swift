@testable import TTFreeCell
import Testing
import Foundation

private struct ExportStateTests {
    @Test("button texts are correct")
    func texts() {
        let subject = ExportState()
        #expect(subject.exportText == "You can export the current deal as text, suitable for sending to a friend to play or for pasting into an online solver.")
        #expect(subject.importText == "You can import an exported deal to play it; copy the exported deal, paste it here, and tap Import and Deal.")
    }
}
