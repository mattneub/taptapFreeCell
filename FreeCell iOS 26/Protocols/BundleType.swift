import Foundation

/// Protocol describing the public face of Bundle, so we can mock it for testing.
protocol BundleType {
    func url(
        forResource name: String?,
        withExtension ext: String?,
        subdirectory subpath: String?
    ) -> URL?
}

extension Bundle: BundleType {}
