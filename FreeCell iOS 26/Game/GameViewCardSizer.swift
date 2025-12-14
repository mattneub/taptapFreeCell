import UIKit

protocol GameViewCardSizerType {
    func cardSize(boardWidth: CGFloat) -> CGSize
}

/// Helper object that computes the size a card view should be, based on the game board width.
struct GameViewCardSizer: GameViewCardSizerType {
    func cardSize(boardWidth: CGFloat) -> CGSize {
        let boardWidth = min(boardWidth, MAXWIDTH)
        // how big should a card be?
        // start by assuming that if the board were 320 points wide, the intercolumn space would be 1
        // so scale that intercolumn space for what the board width _really_ is
        let minimumSpace = max((1.0 / 320.0 * boardWidth).rounded(.awayFromZero), 1.0)
        // fine, so now, given the margins on both edges and the number of columns,
        // subtract the intercolumn spaces to find out how much of our width can consist of cards
        let colcount = 8.0
        let margin = 16.0
        // TODO: but we are not taking account of the leading/trailing safe area
        // (we are just _assuming_ it is zero, and then tossing the magic number 16 around)
        let usableWidth = boardWidth - (2 * margin) - (minimumSpace * (colcount - 1))
        // so in that case, how wide is _one_ card?
        let cardWidth = (usableWidth / colcount).rounded(.towardZero)
        // now use the dimensions of a card drawing to set the height proportionally
        let cardHeight = (cardWidth / CardImage.sourceImageSize.width * CardImage.sourceImageSize.height).rounded()
        // done!
        return CGSize(width: cardWidth, height: cardHeight)
    }
}
