import Foundation

/*
 A Little History
 ================

 After migration 2, stats were stored in two places in the Documents folder. There was a file
 called "stats" which is a property list encoded StatsDictionary, where the keys are each stat's
 `initialLayout.tableauDescription`. This includes `codes` but no `undoStack`. Then there is a
 separate file whose _name_ is the `initialLayout.tableauDescription` (i.e. the same as the
 key in the dictionary file) and whose content is a property list encoded array of Layout, namely
 the corresponding stat's `undoStack`.

 This was actually a very clever division of labor because it revealed so clearly the flaw in the
 entire architecture. My stats dictionary was only 15MB but the accumulated undo stack files
 ran to more than 500MB. Each one is typically less than 70KB but there are a lot of them! The
 "codes" are vastly more compact; each code is just two characters representing a move: the first
 character is the source and the second character is the destination. A digit is a column number,
 "a" thru "d" are the four free cells, and "h" is a foundation ("home").

 However, there is information in the undo stack that is not in the codes. When I generated the
 codes, I recorded only the user's moves. How the computer behaves depends, obviously, on
 whether autoplay and smart endgames is turned on, and whether sequence moves and supermoves
 are performed. But I didn't record that information for each game! Thus although, with some
 experimentation, the game can be reconstructed by a human, I do not know whether the computer
 can be taught to reconstruct the game based on just the codes.

 Nevertheless I would like to delete the undo stack layout files. I could zip them and save
 about half, but it would be better to remove them entirely if they are not needed for anything.
 Thus I would have to remove whatever feature depended upon them.

 One final word: the layout keys (the initial layout) are different than what I now use. So
 in doing any kind of comparison, you have to call `trimmingWhitespacesFromLineEnds` on the
 comparands.
 */

typealias StatsDictionary = [String: Stat]

struct Stat: Equatable, nonisolated Codable { // don't ask
    let dateFinished: Date
    let won: Bool
    let initialLayout: Layout
    let movesCount: Int // meaning _your_ moves; it is merely the count of the `codes`
    let timeTaken: TimeInterval
    // Optional so as not to destroy existing stats
    var codes: [String]? = nil
    // Ditto
    var undoStack: [Layout]? = nil
    // shortcut
    var microsoftDealNumber: Int? { initialLayout.microsoftDealNumber }
}

