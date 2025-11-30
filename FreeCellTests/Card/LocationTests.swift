@testable import TTFreeCell
import Testing

private struct LocationTests {
    @Test("standardNotation: gives expected result")
    func standardNotation() {
        do {
            let subject = Location(category: .foundation, index: 2)
            #expect(subject.standardNotation == "h")
        }
        do {
            let subject = Location(category: .freeCell, index: 0)
            #expect(subject.standardNotation == "a")
        }
        do {
            let subject = Location(category: .freeCell, index: 3)
            #expect(subject.standardNotation == "d")
        }
        do {
            let subject = Location(category: .column, index: 0)
            #expect(subject.standardNotation == "1")
        }
        do {
            let subject = Location(category: .column, index: 7)
            #expect(subject.standardNotation == "8")
        }
    }
}
