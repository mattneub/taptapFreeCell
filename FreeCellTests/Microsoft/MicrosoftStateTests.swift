@testable import TTFreeCell
import Testing
import Foundation

private struct MicrosoftStateTests {
    @Test("dealButtonEnabled is correctly derived")
    func dealButtonEnabled() {
        var subject = MicrosoftState()
        #expect(subject.dealButtonEnabled == true)
        subject.previousDeals = [1, 2]
        #expect(subject.dealButtonEnabled == true)
        subject.currentDealNumber = 1
        #expect(subject.dealButtonEnabled == false)
        subject.currentDealNumber = 2
        #expect(subject.dealButtonEnabled == false)
        subject.currentDealNumber = 3
        #expect(subject.dealButtonEnabled == true)
    }
}
