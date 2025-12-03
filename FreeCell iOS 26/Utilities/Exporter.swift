import Foundation
import Algorithms

protocol ExporterType {
    func messageText(layout: Layout, moves: [String]?) -> String
}

final class Exporter: ExporterType {
    func messageText(layout: Layout, moves: [String]?) -> String {
        let shlomiDescription = layout.shlomiTableauDescription
        var output = """
        This is the game's initial deal in "fc-solve" format:
        
        https://fc-solve.shlomifish.org/docs/distro/README.html
        
        This format is suitable for copying \
        and pasting into TapTapFreeCell's import text view, or \
        into a FreeCell solver such as Shlomi Fish's online solver:
        
        https://fc-solve.shlomifish.org/js-fc-solve/text/
        
        \(shlomiDescription)
        
        """
        if let moves, moves.count > 0 {
            let chunks = moves.chunks(ofCount: 10)
            output += """
            These are your moves in standard format:
            
            https://freecellgamesolutions.com/notation.html
            
            
            """
            for chunk in chunks {
                output += chunk.joined(by: " ") + "\n"
            }
        }
        return output
    }

}
