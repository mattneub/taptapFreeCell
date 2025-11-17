import Foundation

/// Public interface of Data so we can mock it for testing the Stopwatch.
protocol DateType: Sendable {
    init()
    static var timeIntervalToReturn: TimeInterval { get }
    func timeIntervalSince(_ date: DateType) -> TimeInterval
}

extension Date: DateType {
    static var timeIntervalToReturn: TimeInterval { 0 }
    func timeIntervalSince(_ date: DateType) -> TimeInterval {
        if let realDate = date as? Date {
            return timeIntervalSince(realDate)
        }
        return Self.timeIntervalToReturn
    }
}
