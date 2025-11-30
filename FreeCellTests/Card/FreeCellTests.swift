@testable import TTFreeCell
import Testing
import Foundation

private struct FreeCellTests {
    @Test("card and isEmpty work")
    func cardAndIsEmpty() {
        var subject = FreeCell()
        #expect(subject.isEmpty == true)
        #expect(subject.card == nil)
        subject.cards = [Card(rank: .jack, suit: .hearts)]
        #expect(subject.isEmpty == false)
        #expect(subject.card == Card(rank: .jack, suit: .hearts))
    }

    @Test("description works")
    func description() {
        var subject = FreeCell()
        #expect(subject.description == "XX")
        subject.cards = [Card(rank: .jack, suit: .hearts)]
        #expect(subject.description == "JH")
    }

    @Test("accept works")
    func accept() {
        var subject = FreeCell()
        subject.accept(card: Card(rank: .jack, suit: .hearts))
        #expect(subject.card == Card(rank: .jack, suit: .hearts))
    }

    @Test("surrender works")
    func surrender() {
        var subject = FreeCell()
        subject.cards = [Card(rank: .jack, suit: .hearts)]
        let result = subject.surrenderCard()
        #expect(subject.card == nil)
        #expect(result == Card(rank: .jack, suit: .hearts))
    }

    @Test("encodes correctly")
    func encode() throws {
        var subject = FreeCell()
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let encoded = try encoder.encode(subject)
            let encodedString = String(data: encoded, encoding: .utf8)
            let expected = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict/>
            </plist>\n
            """
            #expect(encodedString == expected)
        }
        subject.cards = [Card(rank: .jack, suit: .hearts)]
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let encoded = try encoder.encode(subject)
            let encodedString = String(data: encoded, encoding: .utf8)
            let expected = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>card</key>
                <dict>
                    <key>rank</key>
                    <integer>11</integer>
                    <key>suit</key>
                    <string>H</string>
                </dict>
            </dict>
            </plist>\n
            """.replacingOccurrences(of: "    ", with: "\t")
            #expect(encodedString == expected)
        }
    }

    @Test("decodes correctly")
    func decode() throws {
        do {
            let encoded = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict/>
            </plist>\n
            """
            let data = try #require(encoded.data(using: .utf8))
            let subject = try PropertyListDecoder().decode(FreeCell.self, from: data)
            #expect(subject.cards == [])
        }
        do {
            let encoded = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>card</key>
                <dict>
                    <key>rank</key>
                    <integer>11</integer>
                    <key>suit</key>
                    <string>H</string>
                </dict>
            </dict>
            </plist>\n
            """
            let data = try #require(encoded.data(using: .utf8))
            let subject = try PropertyListDecoder().decode(FreeCell.self, from: data)
            #expect(subject.cards == [Card(rank: .jack, suit: .hearts)])
        }
    }
}
