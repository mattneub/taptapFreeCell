@testable import TTFreeCell
import Testing

private struct OncerTests {
    @Test("Oncer does its thing once and then throws")
    func oncer() throws {
        var variable = 0
        var subject = Oncer {
            variable += $0
        }
        try subject.doYourThing(1)
        #expect(variable == 1)
        #expect(throws: OnceError.tooMany) {
            try subject.doYourThing(1)
        }
        #expect(variable == 1)
    }
}
