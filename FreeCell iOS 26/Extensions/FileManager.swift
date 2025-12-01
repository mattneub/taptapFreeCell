import Foundation

/// Protocol embodying the public face of FileManager, so we can mock it for testing.
protocol FileManagerType: Sendable {
    func countUrlsInDocuments() -> Int
    func urlInDocuments(name: String) -> URL?
    func urlsInDocuments() throws -> [URL]
    func urlInApplicationSupport(name: String) -> URL?
    func removeItem(at: URL) throws
}

/// Convenient extensions on file manager.
extension FileManager: FileManagerType {
    func urlInDocuments(name: String) -> URL? {
        if let documentsUrl = try? url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) {
            return documentsUrl.appendingPathComponent(name)
        }
        return nil
    }

    func urlsInDocuments() throws -> [URL] {
        let documentsUrl = try url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        return try contentsOfDirectory(
            at: documentsUrl,
            includingPropertiesForKeys: nil
        )
    }

    func countUrlsInDocuments() -> Int {
        if let list = try? urlsInDocuments() {
            return list.count
        }
        return 0
    }

    func urlInApplicationSupport(name: String) -> URL? {
        if let applicationSupportUrl = try? url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            return applicationSupportUrl.appendingPathComponent(name)
        }
        return nil
    }
}

