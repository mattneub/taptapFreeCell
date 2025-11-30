import Testing
@testable import TTFreeCell

private struct StringTests {
    @Test("trimming whitespaces from line ends: trims at trailing end")
    func trimming() {
        let subject = """
        \tTesting 
        Testing\t 
         Testing 
        """
        let result = subject.trimmingWhitespacesFromLineEnds
        let expected = "\tTesting\nTesting\n Testing"
        #expect(result == expected)
    }

    @Test("trimming whitespaces from lines: trims at both ends")
    func trimmingBothEnds() {
        let subject = """
        \tTesting 
        Testing\t 
         Testing 
        """
        let result = subject.trimmingWhitespacesFromLines
        let expected = "Testing\nTesting\nTesting"
        #expect(result == expected)
    }
}
