@testable import TTFreeCell
import Testing
import UIKit
import SnapshotTesting

private struct SpeedCellContentViewTests {

    @Test("content view subview is correctly configured, selection is correct")
    func contentViewSubviews() {
        let configuration = SpeedCellContentConfiguration(speed: .glacial)
        let subject = SpeedCellContentView(configuration: configuration)
        #expect(subject.segmentedControl.translatesAutoresizingMaskIntoConstraints == false)
        #expect(subject.segmentedControl.titleForSegment(at: 0) == "Fast")
        #expect(subject.segmentedControl.titleForSegment(at: 1) == "Slow")
        #expect(subject.segmentedControl.titleForSegment(at: 2) == "Glacial")
        #expect(subject.segmentedControl.titleForSegment(at: 3) == "None")
        #expect(subject.segmentedControl.selectedSegmentIndex == 2)
        #expect(subject.segmentedControl.actions(forTarget: nil, forControlEvent: .valueChanged)?.first == "segmentedControlChanged:")
    }

    @Test("content view looks okay")
    func speedCellontentViewAppearance() {
        let configuration = SpeedCellContentConfiguration(speed: .glacial)
        let subject = SpeedCellContentView(configuration: configuration)
        subject.frame = CGRect(x: 0, y: 0, width: 500, height: 52)
        assertSnapshot(of: subject, as: .image)
    }

    @Test("configuration is correctly initialized from speed")
    func configuration() {
        let subject = SpeedCellContentConfiguration(speed: .glacial)
        #expect(subject.speed == .glacial)
    }
}
