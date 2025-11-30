@testable import TTFreeCell
import Testing
import UIKit
import WaitWhile

private struct StatsViewControllerTests {
    let subject = StatsViewController()
    let processor = MockReceiver<StatsAction>()
    let datasource = MockStatsDatasource()

    init() {
        subject.processor = processor
        subject.datasource = datasource
    }

    @Test("recordLabel is correctly constructed")
    func recordLabel() throws {
        let label = subject.recordLabel
        #expect(label.font == UIFont.systemFont(ofSize: 17))
        #expect(label.textAlignment == .center)
        #expect(label.translatesAutoresizingMaskIntoConstraints == false)
        let height = try #require(label.constraints.first)
        #expect(height.constant == 30)
        #expect(height.firstAttribute == .height)
    }

    @Test("sortSegmentedControl is correctly constructed")
    func sortSegmentedControl() async throws {
        let seg = subject.sortSegmentedControl
        #expect(seg.numberOfSegments == 4)
        #expect(seg.titleForSegment(at: 0) == "Date")
        #expect(seg.titleForSegment(at: 1) == "Time")
        #expect(seg.titleForSegment(at: 2) == "Moves")
        #expect(seg.titleForSegment(at: 3) == "Won")
        #expect(seg.isMomentary == true)
        #expect(seg.translatesAutoresizingMaskIntoConstraints == false)
        #expect(seg.selectedSegmentIndex == -1)
        let height = try #require(seg.constraints.first)
        #expect(height.constant == 22)
        #expect(height.firstAttribute == .height)
        seg.sendActions(for: .valueChanged)
        await #while(datasource.thingsReceived.isEmpty)
        #expect(datasource.thingsReceived == [.sort(.date)])
    }

    @Test("tableHeaderView is correctly constructed")
    func tableHeaderView() {
        let view = subject.tableHeaderView
        #expect(subject.sortSegmentedControl.isDescendant(of: view))
        #expect(subject.recordLabel.isDescendant(of: view))
        // good enough
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

    @Test("viewDidLoad: sets the spinner container as table view's background view, starts spinning; adds right button, table header view")
    func viewDidLoad() async throws {
        subject.loadViewIfNeeded()
        #expect(subject.tableView.backgroundView === subject.spinnerContainer)
        #expect(subject.spinner.isAnimating)
        let button = try #require(subject.navigationItem.rightBarButtonItem)
        #expect(button.title == "Numbered")
        #expect(button.target === subject)
        #expect(button.action == #selector(subject.doMicrosofts))
        #expect(subject.tableView.tableHeaderView === subject.tableHeaderView)
    }

    @Test("viewWillLayoutSubviews: set table view header height, segmented control widths")
    func viewWillLayoutSubviews() {
        let view = subject.view!
        let width = 100 + 125 + 125 + 50 + 8 + 8 + 8 + 8 + 8
        view.frame = CGRect(x: 0, y: 0, width: width, height: 400)
        let viewController = UIViewController()
        makeWindow(viewController: viewController)
        viewController.view.addSubview(view)
        viewController.view.layoutIfNeeded()
        #expect(subject.tableView.tableHeaderView?.bounds.height == 60)
        #expect(subject.sortSegmentedControl.widthForSegment(at: 3) == 62)
        #expect(subject.sortSegmentedControl.widthForSegment(at: 0) == 112)
        #expect(subject.sortSegmentedControl.widthForSegment(at: 1) == 0) // automatic
        #expect(subject.sortSegmentedControl.widthForSegment(at: 2) == 0) // automatic
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
    func presentDatasource() async {
        await subject.present(StatsState())
        #expect(datasource.statesPresented == [StatsState()])
    }

    @Test("receive totalChanged: shows table header view, configures record label")
    func totalChanged() async {
        subject.tableHeaderView.isHidden = true
        await subject.receive(.totalChanged(total: 2, won: 3))
        #expect(subject.tableHeaderView.isHidden == false)
        #expect(subject.recordLabel.text == "Played 2, Won 3")
    }

    @Test("doMicrosofts: sends toggleMicrosofts")
    func doMicrosofts() async {
        subject.doMicrosofts()
        await #while(datasource.thingsReceived.isEmpty)
        #expect(datasource.thingsReceived == [.toggleMicrosofts])
    }
}
