import Testing
@testable import TTFreeCell

private struct DictionaryTests {
    @Test("mapKeys: does what it says on the tin")
    func mapKeys() {
        let subject: [String: String] = [" manny   ": "pep1", " moe    ": "pep2"]
        let result = subject.mapKeys { $0.trimmingWhitespacesFromLineEnds } // case in point
        #expect(result == [" manny": "pep1", " moe": "pep2"])
    }
}
