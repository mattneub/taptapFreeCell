@testable import TTFreeCell
import Testing
import Foundation

private struct EndgameTests {
    let subject = Endgame()
    let helper = MockEndgameHelper()
    let extraPly = MockEndgameExtraPly()

    init() {
        subject.helper = helper
        subject.extraPly = extraPly
    }

    @Test("paths is correctly initialized")
    func paths() {
        let expected: [[EndgameStep]] = [
            [.splat1(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 7), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 7), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 7), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 7), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 7), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 7), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 7), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 7), .autoplay],
        ]
        #expect(subject.paths == expected)
    }

    @Test("basic functionality: runs thru paths calling shift, autoplay, or splat on each step")
    func basicFunctionality() {
        subject.paths = [
            [.splat1(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 7), .autoplay],
        ]
        // to test the base case, we make the helper return a different layout on each call
        var layouts = [Layout(), Layout(), Layout(), Layout(), Layout(), Layout(), Layout(), Layout()]
        for index in 0..<8 {
            layouts[index].columns[index].cards = [Card(rank: .ace, suit: .spades)]
        }
        helper.layoutsToReturn = layouts
        let start = Layout()
        let result = subject.evaluate(start)
        #expect(helper.methodsCalled == [
            "splat(layout:index:)", "autoplay(layout:)",
            "splat(layout:index:)", "autoplay(layout:)",
            "shift(layout:index:)", "autoplay(layout:)",
            "splat(layout:index:)", "autoplay(layout:)",
        ])
        let expected: [Layout] = [start] + layouts[0..<3] + [start] + layouts[4..<7]
        #expect(helper.layoutsPassedIn == expected)
        #expect(helper.indexes == [0, 0, 7, 7])
        #expect(result == [])
    }

    @Test("shortcutting: if splat1 has no effect on a column, encountering same step with same column skips entire path")
    func shortCuttingSplat1() {
        subject.paths = [
            [.splat1(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 7), .autoplay, .shift1(column: 0), .autoplay],
        ]
        var layouts = [Layout(), Layout(), Layout(), Layout(), Layout(), Layout(), Layout(), Layout()]
        for index in 0..<8 {
            layouts[index].columns[index].cards = [Card(rank: .ace, suit: .spades)]
        }
        helper.layoutsToReturn = layouts
        var start = Layout()
        start.columns[0].cards = [Card(rank: .ace, suit: .spades)]
        let result = subject.evaluate(start)
        #expect(helper.methodsCalled == [
            "splat(layout:index:)",
            "splat(layout:index:)", "autoplay(layout:)",
            "shift(layout:index:)", "autoplay(layout:)",
        ])
        let expected: [Layout] = [start] + [start] + layouts[1..<4]
        #expect(helper.layoutsPassedIn == expected)
        #expect(helper.indexes == [0, 7, 0])
        #expect(result == [])
    }

    @Test("shortcutting: if shift1 has no effect on a column, encountering same step with same column skips entire path")
    func shortCuttingShift1() {
        subject.paths = [
            [.shift1(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 7), .autoplay, .shift1(column: 1), .autoplay],
        ]
        var layouts = [Layout(), Layout(), Layout(), Layout(), Layout(), Layout(), Layout(), Layout()]
        for index in 0..<8 {
            layouts[index].columns[index].cards = [Card(rank: .ace, suit: .spades)]
        }
        helper.layoutsToReturn = layouts
        var start = Layout()
        start.columns[0].cards = [Card(rank: .ace, suit: .spades)]
        let result = subject.evaluate(start)
        #expect(helper.methodsCalled == [
            "shift(layout:index:)",
            "splat(layout:index:)", "autoplay(layout:)",
            "shift(layout:index:)", "autoplay(layout:)",
        ])
        let expected: [Layout] = [start] + [start] + layouts[1..<4]
        #expect(helper.layoutsPassedIn == expected)
        #expect(helper.indexes == [0, 7, 1])
        #expect(result == [])
    }

    @Test("shortcutting: if splat2 has no effect, the rest of that path is skipped")
    func shortCuttingSplat2() {
        subject.paths = [
            [.shift1(column: 0), .autoplay, .splat2(column: 1), .autoplay, .autoplay, .autoplay],
            [.splat1(column: 7)],
        ]
        var layouts = [Layout(), Layout(), Layout(), Layout(), Layout(), Layout(), Layout(), Layout()]
        for index in 0..<8 {
            layouts[index].columns[0].cards = [Card(rank: .ace, suit: .spades)]
        }
        helper.layoutsToReturn = layouts
        let start = Layout()
        let result = subject.evaluate(start)
        #expect(helper.methodsCalled == [
            "shift(layout:index:)", "autoplay(layout:)", "splat(layout:index:)", // no autoplays, on to next path
            "splat(layout:index:)"
        ])
        let expected: [Layout] = [start] + layouts[0..<2] + [start]
        #expect(helper.layoutsPassedIn == expected)
        #expect(helper.indexes == [0, 1, 7])
        #expect(result == [])
    }

    @Test("finish: if a path ends with empty columns and freecells, all differing successive layouts are returned")
    func finish() {
        subject.paths = [
            [.shift1(column: 0), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 3), .autoplay],
        ]
        var layouts = [Layout(), Layout(), Layout(), Layout(), Layout(), Layout(), Layout(), Layout()]
        // first step does not end with a win, its layouts are thrown away
        for index in 0..<4 {
            layouts[index].columns[index].cards = [Card(rank: .ace, suit: .spades)]
        }
        // second step first returns two identical layouts, represented _once_ in result
        for index in 4..<6 {
            layouts[index].columns[1].cards = [Card(rank: .ace, suit: .spades)]
        }
        // second state then ends with a win, represented _once_ at end of result
        for index in 6..<8 {
            layouts[index].foundations[0].cards = [Card(rank: .ace, suit: .spades)]
        }
        helper.layoutsToReturn = layouts
        let start = Layout()
        let result = subject.evaluate(start)
        #expect(helper.methodsCalled == [
            "shift(layout:index:)", "autoplay(layout:)",
            "splat(layout:index:)", "autoplay(layout:)",
            "shift(layout:index:)", "autoplay(layout:)",
            "splat(layout:index:)", "autoplay(layout:)",
        ])
        #expect(helper.indexes == [0, 1, 2, 3])
        #expect(result.count == 2)
        #expect(result[0].columns[1].cards == [Card(rank: .ace, suit: .spades)])
        #expect(result[1].foundations[0].cards == [Card(rank: .ace, suit: .spades)])
    }

    @Test("extra ply: called if three or four layouts succeed in a path")
    func extraPlyLayoutCount() {
        subject.paths = [
            [.splat1(column: 0), .autoplay, .splat2(column: 0), .autoplay],
        ]
        // four, yes
        var layouts = [Layout(), Layout(), Layout(), Layout()]
        for index in 0..<4 {
            layouts[index].columns[index].cards = [Card(rank: .ace, suit: .spades)]
        }
        helper.layoutsToReturn = layouts
        let start = Layout()
        _ = subject.evaluate(start)
        #expect(extraPly.methodsCalled == ["doExtraPly(_:)"])
        #expect(extraPly.layouts == layouts)
        // three, yes
        extraPly.methodsCalled = []
        extraPly.layouts = []
        layouts = [Layout(), Layout(), Layout(), Layout()]
        for index in 0..<4 {
            layouts[index].columns[index].cards = [Card(rank: .ace, suit: .spades)]
        }
        layouts[0] = layouts[1]
        helper.layoutsToReturn = layouts
        _ = subject.evaluate(start)
        #expect(extraPly.methodsCalled == ["doExtraPly(_:)"])
        #expect(extraPly.layouts == Array(layouts[1..<4]))
        // two, no
        extraPly.methodsCalled = []
        extraPly.layouts = []
        layouts = [Layout(), Layout(), Layout(), Layout()]
        for index in 0..<4 {
            layouts[index].columns[index].cards = [Card(rank: .ace, suit: .spades)]
        }
        layouts[1] = layouts[2]
        layouts[0] = layouts[1]
        helper.layoutsToReturn = layouts
        _ = subject.evaluate(start)
        #expect(extraPly.methodsCalled.isEmpty)
    }

    @Test("extraPly: called if last layout has fewer than 44 cards outstanding")
    func extraPlyCardCount() {
        subject.paths = [
            [.splat1(column: 0), .autoplay, .splat2(column: 0), .autoplay],
        ]
        // 43, yes
        var layouts = [Layout(), Layout(), Layout(), Layout()]
        for index in 0..<3 {
            layouts[index].columns[index].cards = [Card(rank: .ace, suit: .spades)]
        }
        layouts[3].columns[0].cards = Array<Card>(repeating: Card(rank: .king, suit: .spades), count: 43)
        helper.layoutsToReturn = layouts
        let start = Layout()
        _ = subject.evaluate(start)
        #expect(extraPly.methodsCalled == ["doExtraPly(_:)"])
        // 44, no
        extraPly.methodsCalled = []
        layouts[3].columns[0].cards = Array<Card>(repeating: Card(rank: .king, suit: .spades), count: 44)
        helper.layoutsToReturn = layouts
        _ = subject.evaluate(start)
        #expect(extraPly.methodsCalled.isEmpty)
    }

    @Test("extraPly: if it returns non-nil list of layouts, that list is returned from evaluate")
    func extraPlyReturn() {
        subject.paths = [
            [.splat1(column: 0), .autoplay, .splat2(column: 0), .autoplay],
        ]
        var layouts = [Layout(), Layout(), Layout(), Layout()]
        for index in 0..<4 {
            layouts[index].columns[index].cards = [Card(rank: .ace, suit: .spades)]
        }
        helper.layoutsToReturn = layouts
        let start = Layout()
        let result = subject.evaluate(start)
        #expect(extraPly.methodsCalled == ["doExtraPly(_:)"])
        #expect(result == [])
        extraPly.layoutsToReturn = [Layout()]
        helper.layoutsToReturn = layouts
        let result2 = subject.evaluate(start)
        #expect(result2 == [Layout()])
    }
}
