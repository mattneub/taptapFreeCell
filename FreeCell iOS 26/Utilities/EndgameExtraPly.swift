import Foundation

protocol EndgameExtraPlyType {
    func doExtraPly(_ layouts: [Layout]) -> [Layout]?
}

/// Class that embodies additional logic for adding an extra ply to an endgame path.
final class EndgameExtraPly: EndgameExtraPlyType {
    /// Our helper object. It is a var so we can mock it for testing.
    var helper: any EndgameHelperType = EndgameHelper()

    /// Do an extra ply of one splat and one autoplay after the last accumulated proposed layout.
    /// - Parameter layouts: Accumulated layouts from the path.
    /// - Returns: Winning series of layouts (original accumulated layouts plus more), or nil if no win.
    func doExtraPly(_ layouts: [Layout]) -> [Layout]? {
        var layouts = layouts
        for index in 0..<8 {
            guard var firstLayout = layouts.last else {
                return nil // will never happen; we wouldn't be here unless there were layouts
            }
            let firstLayoutBeforeSplat = firstLayout
            helper.splat(layout: &firstLayout, index: index)
            if firstLayout == firstLayoutBeforeSplat {
                continue
            }
            if firstLayout.numberOfCardsRemaining == 0 { // very unlikely
                layouts.append(firstLayout)
                return layouts
            }
            var secondLayout = firstLayout
            helper.autoplay(layout: &secondLayout)
            if secondLayout.numberOfCardsRemaining == 0 {
                layouts.append(firstLayout)
                layouts.append(secondLayout)
                return layouts
            }
        }
        return nil
    }
}
