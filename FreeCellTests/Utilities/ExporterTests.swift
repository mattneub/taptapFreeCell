@testable import TTFreeCell
import Testing
import Foundation

private struct ExporterTests {
    let subject = Exporter()

    @Test("message text is right with no codes")
    func messageTextNoCodes() {
        var layout = Layout()
        layout.columns[0].cards = [Card(rank: .jack, suit: .hearts)]
        let result = subject.messageText(layout: layout, moves: nil)
        let expected = """
        This is the game's initial deal in "fc-solve" format:
        
        https://fc-solve.shlomifish.org/docs/distro/README.html
        
        This format is suitable for copying and pasting into TapTapFreeCell's import text view, or into a FreeCell solver such as Shlomi Fish's online solver:
        
        https://fc-solve.shlomifish.org/js-fc-solve/text/
        
        JH
        
        
        
        
        
        
        
        
        
        """
        #expect(result == expected)
    }

    @Test("message text is right with codes")
    func messageTextCodes() {
        var layout = Layout()
        layout.columns[0].cards = [Card(rank: .jack, suit: .hearts)]
        let moves = Array(repeating: "aa", count: 21)
        let result = subject.messageText(layout: layout, moves: moves)
        let expected = """
        This is the game's initial deal in "fc-solve" format:
        
        https://fc-solve.shlomifish.org/docs/distro/README.html
        
        This format is suitable for copying and pasting into TapTapFreeCell's import text view, or into a FreeCell solver such as Shlomi Fish's online solver:
        
        https://fc-solve.shlomifish.org/js-fc-solve/text/
        
        JH
        
        
        
        
        
        
        
        
        These are your moves in standard notation:
        
        https://www.solitairelaboratory.com/solutioncatalog.html
        
        aa aa aa aa aa aa aa aa aa aa
        aa aa aa aa aa aa aa aa aa aa
        aa
        
        """
        #expect(result == expected)
    }
}
