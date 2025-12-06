import UIKit
@testable import TTFreeCell

final class MockSafariProvider: SafariProviderType {
    var methodsCalled = [String]()
    var url: URL?

    func provide(for url: URL) -> UIViewController {
        methodsCalled.append(#function)
        self.url = url
        return MockSafariViewController()
    }
}

final class MockSafariViewController: UIViewController {}
