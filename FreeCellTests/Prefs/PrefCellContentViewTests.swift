@testable import TTFreeCell
import Testing
import UIKit
import SnapshotTesting

private struct PrefCellContentViewTests {

    @Test("content view subviews are correctly configured")
    func contentViewSubviews() {
        let pref = Pref(key: .automoveToFoundations, value: true)
        let configuration = PrefCellContentConfiguration(pref: pref)
        let subject = PrefCellContentView(configuration: configuration)
        #expect(subject.prefLabel.translatesAutoresizingMaskIntoConstraints == false)
        #expect(subject.prefLabel.font == UIFont.systemFont(ofSize: 17))
        #expect(subject.prefSwitch.translatesAutoresizingMaskIntoConstraints == false)
        #expect(subject.prefSwitch.actions(forTarget: nil, forControlEvent: .valueChanged)?.first == "prefSwitchChanged:")
    }

    @Test("setting the content view's configuration configures the view correctly")
    func contentView() throws {
        let pref = Pref(key: .automoveToFoundations, value: true)
        let configuration = PrefCellContentConfiguration(pref: pref)
        let subject = PrefCellContentView(configuration: configuration)
        #expect(subject.prefLabel.text == "Automove To Foundations")
        #expect(subject.prefSwitch.isOn == true)
        #expect(subject.prefSwitch.prefKey == .automoveToFoundations)
        #expect(subject.labelLeftConstraint?.constant == 8)
    }

    @Test("setting the content view's configuration configures the view correctly for a subordinate pref")
    func contentViewSubordinate() throws {
        let pref = Pref(key: .earlyEndgame, value: true)
        let configuration = PrefCellContentConfiguration(pref: pref)
        let subject = PrefCellContentView(configuration: configuration)
        #expect(subject.prefLabel.text == "Early Endgame")
        #expect(subject.prefSwitch.isOn == true)
        #expect(subject.prefSwitch.prefKey == .earlyEndgame)
        #expect(subject.labelLeftConstraint?.constant == 24) // *
    }

    @Test("content view looks okay")
    func prefCellContentViewAppearance() {
        let pref = Pref(key: .automoveToFoundations, value: true)
        let configuration = PrefCellContentConfiguration(pref: pref)
        let subject = PrefCellContentView(configuration: configuration)
        subject.frame = CGRect(x: 0, y: 0, width: 500, height: 52)
        assertSnapshot(of: subject, as: .image)
    }

    @Test("configuration is correctly initialized from pref")
    func configuration() {
        let pref = Pref(key: .automoveToFoundations, value: true)
        let subject = PrefCellContentConfiguration(pref: pref)
        #expect(subject.prefKey == .automoveToFoundations)
        #expect(subject.text == "Automove To Foundations")
        #expect(subject.isSubordinate == false)
        #expect(subject.value == true)
    }

    @Test("configuration is correctly initialized from subordinate pref")
    func configurationSubordinate() {
        let pref = Pref(key: .earlyEndgame, value: true)
        let subject = PrefCellContentConfiguration(pref: pref)
        #expect(subject.prefKey == .earlyEndgame)
        #expect(subject.text == "Early Endgame")
        #expect(subject.isSubordinate == true) // *
        #expect(subject.value == true)
    }
}
