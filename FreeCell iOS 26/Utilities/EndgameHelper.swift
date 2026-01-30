protocol EndgameHelperType {
    func autoplay(layout: inout Layout)
    func splat(layout: inout Layout, index: Int)
    func shift(layout: inout Layout, index: Int)
}

/// Class that helps the Endgame class by performing the operations on a layout.
/// This is to separate responsibilities and make things easier to test.
final class EndgameHelper: EndgameHelperType {
    func autoplay(layout: inout Layout) {
        layout.autoplay()
    }

    /// Splat as many cards as possible from the column with the given index to empty spaces,
    /// not forgetting to try the foundations first for each card.
    func splat(layout: inout Layout, index: Int) {
        guard layout.columns[index].cards.count > 1 else {
            return
        }
        for _ in 1..<layout.columns[index].cards.count {
            if layout.playToFoundationIfSafeAndPossible(location: Location(category: .column, index: index)) {
                continue // if we _can_ play to the foundations, we _did_ play to the foundations
            }
            if let freeCellIndex = layout.indexOfFirstEmptyFreeCell {
                let card = layout.columns[index].surrenderCard()
                layout.freeCells[freeCellIndex].accept(card: card)
            } else if let columnIndex = layout.indexOfFirstEmptyColumn {
                let card = layout.columns[index].surrenderCard()
                layout.columns[columnIndex].accept(card: card)
            } else {
                break
            }
        }
    }

    /// If the whole column is not a sequence, and you can move the whole max sequence into a
    /// blank column, move it.
    func shift(layout: inout Layout, index: Int) {
        guard let destinationIndex = layout.indexOfFirstEmptyColumn else {
            return
        }
        let movables = layout.howManyCardsCanMoveLegally(
            from: index,
            to: destinationIndex,
            sequenceMoves: true,
            supermoves: true
        )

        let maxMovables = layout.columns[index].maxMovableSequence.count
        if movables == maxMovables {
            layout.columns[index].cards.suffix(movables).forEach {
                layout.columns[destinationIndex].accept(card: $0)
            }
            layout.columns[index].cards.removeLast(movables)
        }
    }
}
