import Foundation

struct MicrosoftState: Equatable {
    var currentDealNumber: Int = 0
    var dealButtonEnabled: Bool { !previousDeals.contains(currentDealNumber) }
    var previousDeals: Set<Int> = []
}
