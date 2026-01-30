import Foundation

/// The overall game state, i.e. what cards are in what piles.
struct Layout: CustomStringConvertible, Codable, Equatable {
    init() {} // to distinguish from init(shlomiTableauDescription:)

    var foundations: [Foundation] = Suit.foundationOrder.map { Foundation(suit: $0) }

    func indexOfFoundation(for suit: Suit) -> Int {
        return Suit.foundationOrder.firstIndex(of: suit) ?? -1
    }

    // TODO: eliminate if not using
    func foundation(for suit: Suit) -> Foundation {
        return foundations[indexOfFoundation(for: suit)]
    }

    var columns = [Column](repeating: Column(), count: 8)

    var freeCells = [FreeCell](repeating: FreeCell(), count: 4)

    var numberOfEmptyFreeCells: Int {
        freeCells.filter{ $0.isEmpty }.count
    }

    var indexOfFirstEmptyFreeCell: Int? {
        freeCells.firstIndex { $0.isEmpty }
    }

    var numberOfEmptyColumns: Int {
        columns.filter{ $0.isEmpty }.count
    }

    var indexOfFirstEmptyColumn: Int? {
        columns.firstIndex { $0.isEmpty }
    }

    var numberOfCardsRemaining: Int { // i.e. remaining in play — not in the foundations
        (freeCells as [any Source] + columns as [any Source]).reduce(0) { $0 + $1.cards.count }
    }

    /// Rough measure of how close we are to a win.
    var entropy: Double {
        var sequentialCount = 0
        var totalCount = 0
        for column in columns {
            if column.cards.count == 1 {
                totalCount += 1
                sequentialCount += 1
            } else if column.cards.count > 1 {
                totalCount += column.cards.count - 1
                for index in 1..<column.cards.count {
                    if column.cards[index].canGoOn(column.cards[index-1]) {
                        sequentialCount += 1
                    }
                }
            }
        }
        let result = Double(sequentialCount) / Double(totalCount)
        if result.isNaN {
            return 0
        }
        return result
    }

    /// Convert from a location to its corresponding `card`.
    /// - Parameter location: The location in the layout.
    /// - Returns: The card, or `nil` if the location is empty.
    func card(at location: Location) -> Card? {
        let group: [any Destination] = switch location.category {
        case .foundation: foundations
        case .freeCell: freeCells
        case .column: columns
        }
        return group[location.index].card
    }

    /// Convert from a location and "internal index" to the corresponding card.
    /// - Parameters:
    ///   - location: The location in the layout.
    ///   - internalIndex: The index within that location, or -1 to use the `card` property.
    /// - Returns: The card, or `nil` if no actual card could be found.
    func card(at location: Location, internalIndex: Int) -> Card? {
        if internalIndex == -1 {
            return card(at: location)
        }
        let group: [any Destination] = switch location.category {
        case .foundation: foundations
        case .freeCell: freeCells
        case .column: columns
        }
        let cards = group[location.index].cards
        if cards.indices.contains(internalIndex) {
            return cards[internalIndex]
        }
        return nil
    }

    /// Convert from a location to its corresponding source `card`,
    /// e.g. the card that would move from here to a foundation if possible, and
    /// _remove_ that card as well as returning it.
    /// - Parameter location: The location in the layout.
    /// - Returns: The card, or `nil` if the location is empty.
    mutating func surrenderCard(from location: Location) -> Card {
        func surrender<T: Source>(from sources: inout [T]) -> Card {
            sources[location.index].surrenderCard()
        }
        return switch location.category {
        case .foundation: fatalError("not a source")
        case .freeCell: surrender(from: &freeCells)
        case .column: surrender(from: &columns)
        }
    }

    /// List all locations that contain cards, along with their cards.
    /// This means returning _three_ pieces of information, exactly the three pieces
    /// that a LocationAndCard supplies: the location, the index of the card _within_ the
    /// cards of the location, and the card.
    func allLocationsAndCards() -> [LocationAndCard] {
        var result = [LocationAndCard]()
        for index in foundations.indices {
            let cards = foundations[index].cards
            for internalIndex in cards.indices {
                result.append(
                    LocationAndCard(
                        location: Location(category: .foundation, index: index),
                        internalIndex: internalIndex,
                        card: cards[internalIndex]
                    )
                )
            }
        }
        for index in freeCells.indices {
            let cards = freeCells[index].cards
            for internalIndex in cards.indices {
                result.append(
                    LocationAndCard(
                        location: Location(category: .freeCell, index: index),
                        internalIndex: internalIndex,
                        card: cards[internalIndex]
                    )
                )
            }
        }
        for index in columns.indices {
            let cards = columns[index].cards
            for internalIndex in cards.indices {
                result.append(
                    LocationAndCard(
                        location: Location(category: .column, index: index),
                        internalIndex: internalIndex,
                        card: cards[internalIndex]
                    )
                )
            }
        }
        return result
    }

    mutating func deal(_ deck: any DeckType) {
        var deck = deck
        foundations.modifyEach {
            $0.cards = []
        }
        columns.modifyEach {
            $0.cards = []
        }
        freeCells.modifyEach {
            $0.cards = []
        }
        self.microsoftDealNumber = nil
        while !deck.isEmpty {
            columns.modifyEach {
                if !deck.isEmpty {
                    $0.cards.append(deck.deal())
                }
            }
        }
    }

    var microsoftDealNumber: Int? = nil

    /// Standard notation of the user move (if there was one) whereby we reached this layout.
    /// At the end of a game, the move codes in the undo stack plus the final layout should
    /// describe the course of the game in human readable form.
    var moveCode: String? = nil

    mutating func deal(microsoftDealNumber: Int) {
        let d = Deck(microsoftDealNumber: microsoftDealNumber)
        self.deal(d)
        self.microsoftDealNumber = microsoftDealNumber // in that order, since `deal` will nilify first
    }

    /// We can follow a policy of moving unneeded cards automatically to foundations.
    /// Therefore we need a way of knowing whether a given card is truly unneeded.
    func mightNeed(card: Card) -> Bool {
        if card.rank == .ace { return false }
        if card.rank == .two { return false }

        // NOTE: we call an empty foundation's rank zero to cover a case like e.g.
        // what's up is 2S, AH, 2D, then 3S is not needed
        // http://www.solitairelaboratory.com/fcfaq.html

        // Simplest case: if both cards that can go directly on this card are up, this card
        // is not needed
        let oppositeFoundations = card.suit.suitsOfOppositeColor.map {
            foundations[$0.foundationOrderIndex]
        }
        if oppositeFoundations.allSatisfy ({
            ($0.card?.rank.rawValue ?? 0) >= card.rank.rawValue - 1
        }) {
            return false
        }

        // Sophisticated case:
        // "In general, it is completely safe to autoplay a card when any possible card
        // that could be packed onto it on a tableau column has already been played
        // to the foundation, _or can be played there as soon as it is uncovered._
        // For example, a seven of diamonds is safe to autoplay (onto a six of diamonds
        // already there) when both black fives and the four of hearts are already
        // on the foundations. The only cards which could still be packed
        // on the seven of diamonds are the black sixes and the five of hearts
        // (all of which could be autoplayed), since both black fours are gone."
        // So: if both opposite color foundations are within two ranks of our card ...
        // and the same color opposite suit foundation is within three ranks
        let partnerFoundation = foundations[card.suit.otherSuitOfSameColor.foundationOrderIndex]
        if oppositeFoundations.allSatisfy ({
            ($0.card?.rank.rawValue ?? 0) >= card.rank.rawValue - 2
        }) && (
            (partnerFoundation.card?.rank.rawValue ?? 0) >= card.rank.rawValue - 3
        ) {
            return false
        }
        return true
    }

    /// Decide whether a sequence move / supermove is possible from the source column to the
    /// destination column, and if so, how many cards would move. Our strategy is first to decide
    /// how many cards could move _in theory_ from the source to the destination, given simply
    /// the surrounding environment (i.e. the number of empty cells). Then we apply that as a
    /// maximum to the _actual_ movable sequence at the bottom of the source.
    private func howManyCardsCanMove(
        from source: Int,
        to destination: Int,
        sequenceMoves: Bool,
        supermoves: Bool
    ) -> Int {
        // simplest case: where there is just one card in play
        if !sequenceMoves || columns[source].maxMovableSequence.count < 2 {
            return (columns[source].card?.canGoOn(columns[destination]) ?? false) ? 1 : 0 // and that's that
        }
        // sequence moves are allowed; right answer depends on whether supermoves are also allowed
        let numberOfEmptyNonDestinationColumns = numberOfEmptyColumns - (columns[destination].isEmpty ? 1 : 0)
        let theoreticalMaximum: Int = if supermoves && numberOfEmptyNonDestinationColumns > 0 {
            // if there is an empty column, we can move maximum of 2 * (free cell spaces + 1) —
            // and it doubles _again_ for every additional extra column! shlomi fish writes:
            // max_cards = (1 + num_vacant_freecells) * (2 ^ num_columns)
            (numberOfEmptyFreeCells + 1) * (1 << numberOfEmptyNonDestinationColumns)
        } else {
            numberOfEmptyFreeCells + numberOfEmptyNonDestinationColumns + 1
        }
        // sequence is in reverse order (bottom to top), so reverse it and extract last max cards
        // look for _first_ of those that can go on the actual column we're being asked to move to
        let walk = columns[source].maxMovableSequence.reversed().suffix(theoreticalMaximum)
        for (index, card) in walk.enumerated() {
            if card.canGoOn(columns[destination]) {
                return walk.count - index
            }
        }
        return 0
    }

    /// Just like (and calls) the previous method, but adding the following proviso: it is not legal
    /// to move _all_ the cards from one column to an empty column (because this would result in
    /// the very same topology and thus would be pointless).
    func howManyCardsCanMoveLegally(
        from source: Int,
        to destination: Int,
        sequenceMoves: Bool,
        supermoves: Bool
    ) -> Int {
        let number = howManyCardsCanMove(
            from: source,
            to: destination,
            sequenceMoves: sequenceMoves,
            supermoves: supermoves
        )
        return if number > 0 && !(
            // cannot move an entire column to an empty column
            columns[source].cards.count == number && columns[destination].isEmpty
        ) {
            number
        } else {
            0
        }
    }

    /// If you can make a safe move from the given location to the foundations, make it and
    /// return true; otherwise, return false.
    /// - Parameter location: The location from which to try to move safely to a foundation.
    /// - Returns: Whether the move was safe and possible. If we return `true`, the move has
    /// been made — the layout has been altered. If we return `false`, nothing has happened at all.
    mutating func playToFoundationIfSafeAndPossible(location: Location) -> Bool {
        if let card = card(at: location) {
            if card.canGoOn(foundations) {
                if !mightNeed(card: card) {
                    let card = surrenderCard(from: location)
                    foundations.accept(card: card)
                    return true
                }
            }
        }
        return false
    }

    /// Do a complete round of automove to foundations. It is up to the caller to save a copy
    /// of the original layout (if desired) to see whether anything changed.
    mutating func autoplay() {
        var moved = false
        let locations: [Location] = (
            (0..<8).map { Location(category: .column, index: $0) } +
            (0..<4).map { Location(category: .freeCell, index: $0) }
        )
        repeat {
            moved = false
            for location in locations {
                if playToFoundationIfSafeAndPossible(location: location) {
                    moved = true
                }
            }
        } while moved
    }

    /// Vertical portrait of the columns, just like the way the game itself looks. This is used
    /// as unique the identifier for a game, because the initial layout when a deal is dealt
    /// consists entirely of columns; thus it is the key in the stats dictionary.
    var tableauDescription: String {
        var output = ""
        // kind of tricky: write until you've hit seven empties in a row
        var maxempty = 0
        var row = 0
        loop: while true {
            for column in self.columns {
                if column.cards.count > row {
                    output.write(column.cards[row].description)
                    maxempty = 0
                } else {
                    output.write("  ")
                    maxempty += 1
                }
                output.write(" ")
                if maxempty > self.columns.count {
                    break loop
                }
            }
            row += 1
            output.write("\n")
        }
        return output.trimmingWhitespacesFromLineEnds // NB this differs from previously
    }

    /// Horizontal portrait of the columns.
    var shlomiTableauDescription: String {
        var output = ""
        for column in self.columns {
            for card in column.cards {
                output.write(card.description)
                output.write(" ")
            }
            output.write("\n")
        }
        return output.trimmingWhitespacesFromLines
    }

    /// Reversal of Shlomi tableau description. Assume the tableau is all there is (i.e. all cards
    /// have just been dealt out) and construct it from the string.
    init?(shlomiTableauDescription input: String) {
        var input = input
        input = input.replacingOccurrences(of: "\n", with: "")
        input = input.replacingOccurrences(of: " ", with: "")
        guard input.count == 104 else { // hard-coded
            return nil
        }
        var cards = [Card]()
        while input.count >= 2 {
            let cardCode = String(input.removeFirst()) + String(input.removeFirst())
            if let card = Card(description: cardCode) {
                cards.append(card)
            } else {
                return nil
            }
        }
        let amounts = [7, 7, 7, 7, 6, 6, 6, 6] // hard-coded
        for colIndex in self.columns.indices {
            self.columns[colIndex].cards.append(contentsOf: cards.prefix(amounts[colIndex]))
            cards.removeFirst(amounts[colIndex])
        }
    }

    // TODO: Taking this out until I am convinced it is needed; I think I was doing export wrong
    /*
    /// Full description of the layout, with foundations portrayed horizontally, and no freecells.
    /// This is because the initial deal might include automatic play to the foundations.
    /// We use this when constructing an export email.
    var shlomiDescription: String {
        var output = ""
        if !(self.foundations.allSatisfy { $0.isEmpty }) {
            output.write("FOUNDS: ")
            for f in (self.foundations.filter { !$0.isEmpty }) {
                output.write(f.top!.suit.description)
                output.write("-")
                output.write(f.top!.rank.description)
                output.write(" ")
            }
            output.write("\n")
        }
        output.write(self.shlomiTableauDescription)
        return output.trimmingWhitespacesFromLines
    }
    */

    /// Full "official" human-readable description of the layout.
    /// Besides being useful for debugging, this is also the basis of Layout equality.
    var description: String {
        var output = ""
        output.write("FOUNDATIONS: ")
        for f in self.foundations {
            output.write(f.card?.description ?? "XX")
            output.write(" ")
        }
        output.write("\n")
        output.write("FREE CELLS:  ") // so that they line up with the foundations
        for fc in self.freeCells {
            output.write(fc.description)
            output.write(" ")
        }
        output.write("\n")
        output.write("\n")
        output.write(self.tableauDescription)
        output.write("\n")
        return output.trimmingWhitespacesFromLineEnds // NB this differs from before
    }

    static func ==(lhs: Layout, rhs: Layout) -> Bool {
        lhs.description == rhs.description
    }
}
