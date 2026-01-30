import Foundation

protocol EndgameType {
    func evaluate(_ layout: Layout) -> [Layout]
}

/// Class that embodies early endgame logic.
final class Endgame: EndgameType {
    /// Our helper object. It is a var so we can mock it for testing.
    var helper: any EndgameHelperType = EndgameHelper()

    /// A path is a single sequence of steps to try.
    var paths: [[EndgameStep]] = []

    /// Create all possible paths. These are our strategies for trying to win in advance.
    init() {
        for index1 in 0..<8 {
            for index2 in 0..<8 {
                paths.append([.splat1(column: index1), .autoplay, .splat2(column: index2), .autoplay])
                paths.append([.shift1(column: index1), .autoplay, .splat2(column: index2), .autoplay])
            }
        }
    }
    
    /// Given a layout, apply each path to it, to see whether that path results in a win.
    /// - Parameter layout: The layout to start with.
    /// - Returns: Array of layouts following on from the original layout, and leading to a win.
    /// If no path leads to a win, the array is empty.
    func evaluate(_ layout: Layout) -> [Layout] {
        // shortcut device: accumulate splat1 and shift1 indexes that made no difference
        var splat1RejectedIndex1s = Set<Int>()
        var shift1RejectedIndex1s = Set<Int>()
    paths:
        for path in paths {
            var layouts = [Layout]()
            for step in path {
                let layoutToTry: Layout = layouts.last ?? layout
                var layout = layoutToTry
                switch step {
                case .autoplay:
                    helper.autoplay(layout: &layout)
                case .shift1(let index):
                    if shift1RejectedIndex1s.contains(index) {
                        continue paths
                    }
                    helper.shift(layout: &layout, index: index)
                    if layout == layoutToTry {
                        shift1RejectedIndex1s.insert(index)
                        continue paths
                    }
                case .splat1(let index):
                    if splat1RejectedIndex1s.contains(index) {
                        continue paths
                    }
                    helper.splat(layout: &layout, index: index)
                    if layout == layoutToTry {
                        splat1RejectedIndex1s.insert(index)
                        continue paths
                    }
                case .splat2(let index):
                    helper.splat(layout: &layout, index: index)
                }
                if layout != layoutToTry {
                    layouts.append(layout)
                }
            }
            if let finalLayout = layouts.last, finalLayout.numberOfCardsRemaining == 0 {
                return layouts
            }
        }
        return []
    }
}

enum EndgameStep: Equatable {
    case autoplay
    case shift1(column: Int) // a shift in position 1 (no such thing as shift in position 2)
    case splat1(column: Int) // a splat in position 1
    case splat2(column: Int) // a splat in position 2
}
