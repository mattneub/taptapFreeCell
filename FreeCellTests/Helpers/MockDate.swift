@testable import FreeCell
import Foundation

final class MockDate: DateType {
    nonisolated(unsafe) var methodsCalled = [String]()
    let uuid: UUID // this is so we can tell one MockDate instance from another

    init() {
        self.uuid = UUID()
        self.methodsCalled.append("init")
    }

    static var timeIntervalToReturn: TimeInterval = 0

    func timeIntervalSince(_ date: any DateType) -> TimeInterval {
        self.methodsCalled.append(#function)
        return Self.timeIntervalToReturn
    }
}
