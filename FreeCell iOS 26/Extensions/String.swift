import Foundation

extension String {
    var trimmingWhitespacesFromLineEnds: String {
        self
            .components(separatedBy: "\n")
            .map { $0.replacing(/\s*$/, with: "") }
            .joined(separator: "\n")
    }
    var trimmingWhitespacesFromLines: String {
        self
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
    }
}
