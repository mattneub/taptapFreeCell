@testable import FreeCell
import UIKit

final class MockFileManager: FileManagerType {
    var methodsCalled = [String]()
    var name: String?
    var applicationSupportURLtoReturn: URL?
    var documentsUTLtoReturn: URL?

    func urlInDocuments(name: String) -> URL? {
        methodsCalled.append(#function)
        self.name = name
        return documentsUTLtoReturn
    }

    func urlInApplicationSupport(name: String) -> URL? {
        methodsCalled.append(#function)
        self.name = name
        return applicationSupportURLtoReturn
    }
}
