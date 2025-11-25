@testable import TTFreeCell
import UIKit

final class MockFileManager: FileManagerType {
    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var name: String?
    nonisolated(unsafe) var applicationSupportURLtoReturn: URL?
    nonisolated(unsafe) var documentsURLtoReturn: URL?

    func urlInDocuments(name: String) -> URL? {
        methodsCalled.append(#function)
        self.name = name
        return documentsURLtoReturn
    }

    func urlInApplicationSupport(name: String) -> URL? {
        methodsCalled.append(#function)
        self.name = name
        return applicationSupportURLtoReturn
    }
}
