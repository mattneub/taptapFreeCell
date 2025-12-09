import Foundation

enum ExportAction: Equatable {
    case cancel
    case export
    case `import`(String?)
    case initialData
}
