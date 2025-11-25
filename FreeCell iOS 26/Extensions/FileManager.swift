import Foundation

/// Protocol embodying the public face of FileManager, so we can mock it for testing.
protocol FileManagerType: Sendable {
    func urlInDocuments(name: String) -> URL?
    func urlInApplicationSupport(name: String) -> URL?
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

