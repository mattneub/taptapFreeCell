@testable import TTFreeCell
import Testing
import UIKit

struct StatCellContentViewTests {
    @Test("Setting the content view's configuration configures the view correctly")
    func contentView() throws {
        let date = Date(timeIntervalSince1970: 0)
        let stat = Stat(dateFinished: date, won: true, initialLayout: Layout(), movesCount: 3, timeTaken: 200)
        let subject = StatCellContentView(configuration: StatCellContentConfiguration(stat: stat))
        #expect(subject.subviews.count == 1)
        let loadedView = try #require(subject.subviews.first)
        #expect(loadedView.subviews.count == 5)
        let labels = loadedView.subviews.filter { $0 is UILabel }
        #expect(labels.count == 5)
        #expect(subject.dateLabel.text == "12/31/1969\n4:00 PM") // wow, that's one fragile test
        #expect(subject.wonLabel.text == "✅")
        #expect(subject.movesLabel.text == "3 moves")
        #expect(subject.timeLabel.text == "00:03:20")
        #expect(subject.supplementaryLabel.text == nil)
    }

    @Test("Setting the content view's configuration configures the view correctly when the game was lost")
    func contentViewGameLost() throws {
        let date = Date(timeIntervalSince1970: 0)
        let stat = Stat(dateFinished: date, won: false, initialLayout: Layout(), movesCount: 3, timeTaken: 200)
        let subject = StatCellContentView(configuration: StatCellContentConfiguration(stat: stat))
        #expect(subject.subviews.count == 1)
        let loadedView = try #require(subject.subviews.first)
        #expect(loadedView.subviews.count == 5)
        let labels = loadedView.subviews.filter { $0 is UILabel }
        #expect(labels.count == 5)
        #expect(subject.dateLabel.text == "12/31/1969\n4:00 PM") // wow, that's one fragile test
        #expect(subject.wonLabel.text == "🚫")
        #expect(subject.movesLabel.text == "")
        #expect(subject.timeLabel.text == "00:03:20")
        #expect(subject.supplementaryLabel.text == nil)
    }

    @Test("Setting the content view's configuration configures the view correctly when the game was microsoft")
    func contentViewGameMicrosoft() throws {
        let date = Date(timeIntervalSince1970: 0)
        var layout = Layout()
        layout.microsoftDealNumber = 42
        let stat = Stat(dateFinished: date, won: false, initialLayout: layout, movesCount: 3, timeTaken: 200)
        let subject = StatCellContentView(configuration: StatCellContentConfiguration(stat: stat))
        #expect(subject.subviews.count == 1)
        let loadedView = try #require(subject.subviews.first)
        #expect(loadedView.subviews.count == 5)
        let labels = loadedView.subviews.filter { $0 is UILabel }
        #expect(labels.count == 5)
        #expect(subject.dateLabel.text == "12/31/1969\n4:00 PM") // wow, that's one fragile test
        #expect(subject.wonLabel.text == "🚫")
        #expect(subject.movesLabel.text == "")
        #expect(subject.timeLabel.text == "00:03:20")
        #expect(subject.supplementaryLabel.text == "Microsoft deal 42")
    }

    @Test("Changing the configuration changes the view as expected")
    func contentViewChangeConfiguration() throws {
        let date = Date(timeIntervalSince1970: 0)
        let stat = Stat(dateFinished: date, won: false, initialLayout: Layout(), movesCount: 3, timeTaken: 200)
        let subject = StatCellContentView(configuration: StatCellContentConfiguration(stat: stat))
        var config = try #require(subject.configuration as? StatCellContentConfiguration)
        config.won = true
        config.movesCount = 4
        subject.configuration = config
        #expect(subject.dateLabel.text == "12/31/1969\n4:00 PM") // wow, that's one fragile test
        #expect(subject.wonLabel.text == "✅")
        #expect(subject.movesLabel.text == "4 moves")
        #expect(subject.timeLabel.text == "00:03:20")
        #expect(subject.supplementaryLabel.text == nil)
    }
}
