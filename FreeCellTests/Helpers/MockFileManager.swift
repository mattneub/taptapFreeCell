@testable import TTFreeCell
import UIKit

final class MockFileManager: FileManagerType {
    nonisolated(unsafe) var methodsCalled = [String]()
    nonisolated(unsafe) var name: String?
    nonisolated(unsafe) var applicationSupportURLtoReturn: URL?
    nonisolated(unsafe) var documentsURLtoReturn: URL?
    nonisolated(unsafe) var countToReturn: Int = 0
    nonisolated(unsafe) var urlsDeleted = [URL]()
    nonisolated(unsafe) var urlsToReturn = [URL]()

    func countUrlsInDocuments() -> Int {
        methodsCalled.append(#function)
        return countToReturn
    }

    func removeItem(at url: URL) throws {
        methodsCalled.append(#function)
        urlsDeleted.append(url)
    }

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

    func urlsInDocuments() throws -> [URL] {
        methodsCalled.append(#function)
        return urlsToReturn
    }
}
