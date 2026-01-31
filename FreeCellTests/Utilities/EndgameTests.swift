@testable import TTFreeCell
import Testing
import Foundation

private struct EndgameTests {
    let subject = Endgame()
    let helper = MockEndgameHelper()

    init() {
        subject.helper = helper
    }

    @Test("paths is correctly initialized")
    func paths() {
        let expected: [[EndgameStep]] = [
            [.splat1(column: 0), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 0), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 0), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 1), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 1), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 2), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 2), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 3), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 3), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 4), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 4), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 5), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 5), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 6), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 6), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 0), .autoplay, .splat2(column: 0), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 1), .autoplay, .splat2(column: 1), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 2), .autoplay, .splat2(column: 2), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 3), .autoplay, .splat2(column: 3), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 4), .autoplay, .splat2(column: 4), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 5), .autoplay, .splat2(column: 5), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 6), .autoplay, .splat2(column: 6), .autoplay],
            [.splat1(column: 7), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
            [.shift1(column: 7), .autoplay, .splat2(column: 7), .autoplay, .splat2(column: 7), .autoplay],
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
        helper.layoutsToReturn = layouts // NB mock layouts return in reverse order
        let start = Layout()
        let result = subject.evaluate(start)
        #expect(helper.methodsCalled == [
            "splat(layout:index:)", "autoplay(layout:)",
            "splat(layout:index:)", "autoplay(layout:)",
            "shift(layout:index:)", "autoplay(layout:)",
            "splat(layout:index:)", "autoplay(layout:)",
        ])
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
        helper.layoutsToReturn = layouts // NB mock layouts return in reverse order
        var start = Layout()
        start.columns[7].cards = [Card(rank: .ace, suit: .spades)]
        let result = subject.evaluate(start)
        #expect(helper.methodsCalled == [
            "splat(layout:index:)",
            "splat(layout:index:)", "autoplay(layout:)",
            "shift(layout:index:)", "autoplay(layout:)",
        ])
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
        helper.layoutsToReturn = layouts // NB mock layouts return in reverse order
        var start = Layout()
        start.columns[7].cards = [Card(rank: .ace, suit: .spades)]
        let result = subject.evaluate(start)
        #expect(helper.methodsCalled == [
            "shift(layout:index:)",
            "splat(layout:index:)", "autoplay(layout:)",
            "shift(layout:index:)", "autoplay(layout:)",
        ])
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
        helper.layoutsToReturn = layouts // NB mock layouts return in reverse order
        let start = Layout()
        let result = subject.evaluate(start)
        #expect(helper.methodsCalled == [
            "shift(layout:index:)", "autoplay(layout:)", "splat(layout:index:)", // no autoplays, on to next path
            "splat(layout:index:)"
        ])
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
        for index in 4..<8 {
            layouts[index].columns[index].cards = [Card(rank: .ace, suit: .spades)]
        }
        // second step first returns two identical layouts, represented _once_ in result
        for index in 2..<4 {
            layouts[index].columns[1].cards = [Card(rank: .ace, suit: .spades)]
        }
        // second state then ends with a win, represented _once_ at end of result
        for index in 0..<2 {
            layouts[index].foundations[0].cards = [Card(rank: .ace, suit: .spades)]
        }
        helper.layoutsToReturn = layouts // NB mock layouts return in reverse order
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
}
