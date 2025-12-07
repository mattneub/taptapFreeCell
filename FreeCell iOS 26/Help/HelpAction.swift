import Foundation

enum HelpAction: Equatable {
    case goBack
    case goLeft
    case goRight
    case initialData
    /// Sorry to be a bit tricky here, but there are situations where the processor needs to
    /// add the source page to the undo stack and situation where the processor must not do so.
    /// So the `from` parameter here is an Optional, so that if it is `nil` there will be
    /// nothing to add to the undo stack.
    case navigate(to: String, from: String? = nil)
    case showSafari(url: URL)
    case userSwiped
}
