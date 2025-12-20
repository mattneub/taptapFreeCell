import Foundation

protocol EndgameType {
    func evaluate(_ layout: Layout) -> [Layout]
}

/// Class that embodies early endgame logic.
final class Endgame: EndgameType {
    /// A path is a single sequence of steps to try.
    var paths: [[EndgameStep]] = []

    /// Create all possible paths. These are our strategies for trying to win in advance.
    init() {
        for index1 in 0..<8 {
            for index2 in 0..<8 {
                paths.append([.splat(column: index1), .autoplay, .splat(column: index2), .autoplay])
            }
        }
    }
    
    /// Given a layout, apply each path to it, to see whether that path results in a win.
    /// - Parameter layout: The layout to start with.
    /// - Returns: Array of layouts following on from the original layout, and leading to a win.
    /// If no path leads to a win, the array is empty.
    func evaluate(_ layout: Layout) -> [Layout] {
    paths:
        for path in paths {
            var layouts = [Layout]()
            for (offset, step) in path.enumerated() {
                let layoutToTry: Layout = layouts.last ?? layout
                var layout = layoutToTry
                switch step {
                case .autoplay:
                    layout.autoplay()
                case .splat(let index):
                    if offset == 0 {
                        let column = layout.columns[index]
                        if column.maxMovableSequence.count == column.cards.count {
                            continue paths
                        }
                    }
                    layout.splat(index: index)
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

enum EndgameStep {
    case autoplay
    case splat(column: Int)
}
