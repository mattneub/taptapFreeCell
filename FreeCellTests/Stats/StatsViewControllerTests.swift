@testable import TTFreeCell
import Testing
import UIKit
import WaitWhile

struct StatsViewControllerTests {
    let subject = StatsViewController()
    let processor = MockReceiver<StatsAction>()
    let datasource = MockStatsDatasource()

    init() {
        subject.processor = processor
        subject.datasource = datasource
    }

    @Test("spinner is correctly constructed")
    func spinner() {
        let spinner = subject.spinner
        #expect(spinner.translatesAutoresizingMaskIntoConstraints == false)
        #expect(spinner.hidesWhenStopped == true)
    }

    @Test("spinner container is correctly constructed")
    func spinnerContainer() {
        makeWindow(view: subject.spinnerContainer)
        subject.spinnerContainer.layoutIfNeeded()
        #expect(subject.spinnerContainer.subviews.first === subject.spinner)
        #expect(subject.spinner.frame.center == subject.spinnerContainer.bounds.center)
    }

    @Test("viewDidLoad: sets the spinner container as table view's background view, starts spinning")
    func viewDidLoad() {
        subject.loadViewIfNeeded()
        #expect(subject.tableView.backgroundView === subject.spinnerContainer)
        #expect(subject.spinner.isAnimating)
    }

    @Test("viewDidAppear: first time only, sends initialData")
    func viewDidAppear() async {
        subject.spinner.startAnimating()
        subject.viewDidAppear(false)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.initialData])
        #expect(subject.spinner.isAnimating == false)
        subject.viewDidAppear(false)
        try? await Task.sleep(for: .seconds(0.1))
        #expect(processor.thingsReceived == [.initialData]) // just the one
    }

    @Test("present: passes state on to datasource")
    func present() async {
        await subject.present(StatsState())
        #expect(datasource.statesPresented == [StatsState()])
    }
}
