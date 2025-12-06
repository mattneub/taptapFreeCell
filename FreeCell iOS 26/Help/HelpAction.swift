import Foundation

enum HelpAction: Equatable {
    case goLeft
    case goRight
    case initialData
    case navigate(to: String)
    case showSafari(url: URL)
}
