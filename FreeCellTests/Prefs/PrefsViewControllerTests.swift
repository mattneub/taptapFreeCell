@testable import TTFreeCell
import Testing
import UIKit

private struct PrefsViewControllerTests {
    let subject = PrefsViewController()
    let processor = MockReceiver<PrefsAction>()
    let datasource = MockPrefsDatasource()

    init() {
        subject.processor = processor
        subject.datasource = datasource
    }

    @Test("viewDidLoad: sends initialData")
    func viewDidLoad() {
        subject.loadViewIfNeeded()
        #expect(subject.title == "Settings")
        #expect(processor.thingsReceived == [.initialData])
    }

    @Test("present: passes state on to datasource")
    func present() async {
        await subject.present(PrefsState())
        #expect(datasource.statesPresented == [PrefsState()])
    }

    @Test("receive: passes effect on to datasource")
    func receive() async {
        await subject.receive(.speedChanged(index: 0))
        #expect(datasource.thingsReceived == [.speedChanged(index: 0)])
    }

    @Test("prefSwitchChanged: sends processor prefChanged")
    func prefSwitchChanged() {
        let prefSwitch = PrefSwitch()
        prefSwitch.prefKey = .automoveToFoundations
        prefSwitch.isOn = true
        subject.prefSwitchChanged(prefSwitch)
        #expect(processor.thingsReceived == [.prefChanged(.automoveToFoundations, value: true)])
    }

    @Test("segmentedControlChanged: sends processor speedChanged")
    func segmentedControlChanged() {
        let seg = UISegmentedControl(items: ["hey", "ho"])
        seg.selectedSegmentIndex = 1
        subject.segmentedControlChanged(seg)
        #expect(processor.thingsReceived == [.speedChanged(index: 1)])
    }
}
