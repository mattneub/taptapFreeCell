@testable import TTFreeCell
import Testing
import Foundation

private struct EndgameExtraPlyTests {
    let subject = EndgameExtraPly()
    let helper = MockEndgameHelper()

    init() {
        subject.helper = helper
    }

    @Test("cycle thru 8 indexes: calls splat, if helper returns same layout, keep cycling")
    func cycleContinue() {
        let layouts = [Layout(), Layout(), Layout(), Layout(), Layout(), Layout(), Layout(), Layout()]
        helper.layoutsToReturn = layouts
        let result = subject.doExtraPly([Layout(), Layout(), Layout()])
        #expect(result == nil)
        #expect(helper.methodsCalled == [
            "splat(layout:index:)", "splat(layout:index:)", "splat(layout:index:)", "splat(layout:index:)",
            "splat(layout:index:)", "splat(layout:index:)", "splat(layout:index:)", "splat(layout:index:)",
        ])
        #expect(helper.indexes == [0, 1, 2, 3, 4, 5, 6, 7])
        let expected = layouts
        #expect(helper.layoutsPassedIn == expected)
    }

    @Test("cycle thru indexes; calls splat, if helper returns different layout, calls autoplay")
    func cycleBoth() {
        var layout1 = Layout()
        layout1.columns[1].cards = [Card(rank: .ace, suit: .spades)]
        var layout2 = Layout()
        layout2.columns[2].cards = [Card(rank: .ace, suit: .spades)]
        let layouts = [
            layout1, layout2, layout1, layout2,
            layout1, layout2, layout1, layout2,
            layout1, layout2, layout1, layout2,
            layout1, layout2, layout1, layout2,
        ]
        helper.layoutsToReturn = layouts
        let result = subject.doExtraPly([Layout(), Layout(), Layout()])
        #expect(result == nil)
        #expect(helper.methodsCalled == [
            "splat(layout:index:)", "autoplay(layout:)", "splat(layout:index:)", "autoplay(layout:)", "splat(layout:index:)", "autoplay(layout:)", "splat(layout:index:)", "autoplay(layout:)",
            "splat(layout:index:)", "autoplay(layout:)", "splat(layout:index:)", "autoplay(layout:)", "splat(layout:index:)", "autoplay(layout:)", "splat(layout:index:)", "autoplay(layout:)",
        ])
        #expect(helper.indexes == [0, 1, 2, 3, 4, 5, 6, 7])
        let expected = [
            Layout(), layout1, Layout(), layout1, Layout(), layout1, Layout(), layout1,
            Layout(), layout1, Layout(), layout1, Layout(), layout1, Layout(), layout1,
        ]
        #expect(helper.layoutsPassedIn == expected)
    }

    @Test("cycle thru indexes: if autoplay produces a win, returns original layouts plus layouts from this cycle")
    func cycleWin() {
        var layout1 = Layout()
        layout1.columns[1].cards = [Card(rank: .ace, suit: .spades)]
        var layout2 = Layout()
        layout2.columns[2].cards = [Card(rank: .ace, suit: .spades)]
        let layouts = [
            layout1, layout2,
            layout1, Layout(), // Layout() will count as a win!
        ]
        helper.layoutsToReturn = layouts
        let result = subject.doExtraPly([Layout(), Layout(), Layout()])
        #expect(result == [Layout(), Layout(), Layout(), layout1, Layout()])
        #expect(helper.methodsCalled == [
            "splat(layout:index:)", "autoplay(layout:)", "splat(layout:index:)", "autoplay(layout:)",
        ])
        #expect(helper.indexes == [0, 1])
    }
}
