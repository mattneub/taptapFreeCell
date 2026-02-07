@testable import TTFreeCell

actor MockDealer: DealerType {
    var methodsCalled = [String]()
    var layoutToReturn: Layout?

    func newDeal() async -> Layout {
        methodsCalled.append(#function)
        let freshLayout = await Layout()
        return layoutToReturn ?? freshLayout
    }

    func setLayoutToReturn(_ layout: Layout) {
        layoutToReturn = layout
    }
}
