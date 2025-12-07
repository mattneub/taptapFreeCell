@testable import TTFreeCell
import Testing
import UIKit
import WebKit
import WaitWhile

private struct WebViewViewControllerTests {
    let subject = WebViewViewController()
    let processor = MockReceiver<HelpAction>()
    let bundle = MockBundle()
    static let mockNavigation = WKNavigation()

    init() {
        subject.processor = processor
        services.bundle = bundle
    }

    @Test("viewDidLoad: creates and configures web view")
    func viewDidLoad() throws {
        subject.loadViewIfNeeded()
        let webView = try #require(subject.webView)
        #expect(webView.isDescendant(of: subject.view))
        #expect(webView.navigationDelegate === subject)
        #expect(webView.configuration.suppressesIncrementalRendering == true)
        #expect(webView.alpha == 0)
    }

    @Test("loadPage: gets URL from bundle, sets current page name, calls web view load file if needed")
    func loadPage() throws {
        subject.webViewType = MockWebView.self
        bundle.urlToReturn = URL(string: "file://manny")!
        subject.loadPage(name: "howdy")
        #expect(bundle.methodsCalled == ["url(forResource:withExtension:subdirectory:)"])
        #expect(bundle.name == "howdy")
        #expect(bundle.ext == "html")
        #expect(bundle.subpath == "FreeCellHelpHTML")
        #expect(subject.currentPageName == "howdy")
        let webView = try #require(subject.webView as? MockWebView)
        #expect(webView.methodsCalled == ["loadFileURL(_:allowingReadAccessTo:)"])
        #expect(webView.myUrl == URL(string: "file://manny")!)
        #expect(webView.readAccessURL == URL(string: "file://manny")!)
    }

    @Test("didFinish: sets web view alpha to 1")
    func didFinish() {
        subject.webViewType = MockWebView.self
        subject.loadViewIfNeeded()
        subject.webView?.alpha = 0
        let navigation = Self.mockNavigation // sheesh
        subject.webView(subject.webView!, didFinish: navigation)
        #expect(subject.webView?.alpha == 1)
    }

    @Test("decidePolicy: if navigation type is .other, allows")
    func decideOther() async {
        subject.webViewType = MockWebView.self
        subject.loadViewIfNeeded()
        let request = URLRequest(url: URL(string: "http://www.example.com")!)
        let action = MockNavigationAction(request: request, navigationType: .other)
        let result = await subject.webView(subject.webView!, decidePolicyFor: action)
        #expect(result == .allow)
    }

    @Test("decidePolicy: if host exists, cancels, sends showSafari with URL")
    func decideHost() async {
        subject.webViewType = MockWebView.self
        subject.loadViewIfNeeded()
        let request = URLRequest(url: URL(string: "http://www.example.com")!)
        let action = MockNavigationAction(request: request, navigationType: .linkActivated)
        let result = await subject.webView(subject.webView!, decidePolicyFor: action)
        #expect(result == .cancel)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.showSafari(url: URL(string: "http://www.example.com")!)])
    }

    @Test("decidePolicy: if url scheme is file, if page name is current page name, allows")
    func decideSamePage() async {
        subject.webViewType = MockWebView.self
        subject.loadViewIfNeeded()
        subject.currentPageName = "manny"
        let request = URLRequest(url: URL(string: "file:///path/manny.txt")!)
        let action = MockNavigationAction(request: request, navigationType: .linkActivated)
        let result = await subject.webView(subject.webView!, decidePolicyFor: action)
        #expect(result == .allow)
    }

    @Test("decidePolicy: if url scheme is file, if page name is not current page name, cancels and sends navigate with both pages")
    func decideOtherPage() async {
        subject.webViewType = MockWebView.self
        subject.loadViewIfNeeded()
        subject.currentPageName = "manny"
        let request = URLRequest(url: URL(string: "file:///path/moe.txt")!)
        let action = MockNavigationAction(request: request, navigationType: .linkActivated)
        let result = await subject.webView(subject.webView!, decidePolicyFor: action)
        #expect(result == .cancel)
        await #while(processor.thingsReceived.isEmpty)
        #expect(processor.thingsReceived == [.navigate(to: "moe", from: "manny")])
    }
}

private final class MockWebView: WKWebView {
    var methodsCalled = [String]()
    var myUrl: URL?
    var readAccessURL: URL?

    override func loadFileURL(_ url: URL, allowingReadAccessTo readAccessURL: URL) -> WKNavigation? {
        methodsCalled.append(#function)
        self.myUrl = url
        self.readAccessURL = readAccessURL
        return nil
    }
}

private final class MockNavigationAction: WKNavigationAction {
    let myRequest: URLRequest
    let myNavigationType: WKNavigationType

    override var request: URLRequest { myRequest }
    override var navigationType: WKNavigationType { myNavigationType }

    init(request: URLRequest, navigationType: WKNavigationType) {
        self.myRequest = request
        self.myNavigationType = navigationType
        super.init()
    }
}

