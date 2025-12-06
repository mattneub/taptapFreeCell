import UIKit
import WebKit

class WebViewViewController: UIViewController {
    weak var webView: WKWebView?

    weak var processor: (any Receiver<HelpAction>)?

    /// The type of the web view, so we can inject a mock for testing.
    var webViewType: WKWebView.Type = WKWebView.self

    var currentPageName: String = ""

    override func viewDidLoad() {
        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = true
        let webView = webViewType.init(frame: self.view.bounds, configuration: configuration)
        webView.navigationDelegate = self
        self.view.addSubview(webView)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.webView = webView
        webView.alpha = 0
        webView.allowsLinkPreview = false
    }

    func loadPage(name: String) {
        if let url = services.bundle.url( forResource: name, withExtension: "html", subdirectory: "FreeCellHelpHTML") {
            currentPageName = name
            loadViewIfNeeded()
            webView?.loadFileURL(url, allowingReadAccessTo: url)
        }
    }
}

extension WebViewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.alpha != 1 {
            UIView.animate(withDuration: unlessTesting(0.25)) {
                webView.alpha = 1
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if navigationAction.navigationType == .other { // initial load
            return .allow
        }
        guard let url = navigationAction.request.url else {
            return .cancel
        }
        if url.host != nil {
            Task {
                await processor?.receive(.showSafari(url: url))
            }
            return .cancel
        }
        if url.scheme == "file" { // this is the Really Interesting Part
            guard let fileName = url.lastPathComponent.split(separator: ".").first else {
                return .cancel
            }
            let targetPageName = String(fileName)
            if targetPageName == currentPageName { // internal link, no problem
                return .allow
            }
            Task {
                await processor?.receive(.navigate(to: targetPageName))
            }
            // and fallthrough to return `.cancel`; we will handle this in our own way
        }
        return .cancel
    }
}
