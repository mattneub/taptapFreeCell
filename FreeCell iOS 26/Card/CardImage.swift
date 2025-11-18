import UIKit

struct CardImage {
    // magic numbers
    static let cardImage: String = "easy-reader.png"
    static let sourceImageSize = CGSize(width: 224, height: 296)

    /// Cache for card images.
    static let cardImageCache = NSCache<NSString, UIImage>()

    /// Load the cache and application support with card images.
    static func loadImages() {
        for card in Deck().cards {
            _ = image(for: card, scale: 2)
        }
    }

    /// Supply the image for the given card, using the given scale (which should be the screen
    /// scale). First we try the cache, then we try application supporter, and finally we
    /// draw by copying from the master image.
    static func image(for card: Card, scale: CGFloat) -> UIImage {
        // the card description is the name of the image
        let key = card.description
        // is it in the cache? return it
        if let image = cardImageCache.object(forKey: key as NSString) {
            return image
        }
        // is it on disk? stick it in the cache and _then_ return it
        let url = services.fileManager.urlInApplicationSupport(name: key)
        if let url, let data = try? Data(contentsOf: url) {
            if let image = UIImage(data: data, scale: scale) {
                cardImageCache.setObject(image, forKey: key as NSString)
                return image
            }
        }
        // okay, the hell with it, let's just draw the darned thing
        // magic numbers
        guard let sourceImage = UIImage(named: cardImage) else {
            return UIImage() // shouldn't happen
        }
        guard let suitNumber = Suit.allCases.firstIndex(of: card.suit) else {
            return UIImage() // shouldn't happen
        }
        let rankNumber = card.rank.rawValue - 1
        let cardNumber = suitNumber * 13 + rankNumber
        let offset: CGFloat = 2
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        let width = sourceImageSize.width
        let height = sourceImageSize.height
        xOffset = CGFloat(cardNumber % 9) // integer modulo
        yOffset = CGFloat(cardNumber / 9) // integer division
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(
            size: size,
            format: UIGraphicsImageRendererFormat().applying {
                $0.scale = scale
            }
        )
        let image = renderer.image { _ in
            sourceImage.draw(at: CGPoint(
                x: -offset-(xOffset * width),
                y: -offset-(yOffset * height)
            ))
        }
        // and stick it in the cache
        cardImageCache.setObject(image, forKey: key as NSString)
        // and write it to the disk
        if let url = url {
            try? image.pngData()?.write(to: url)
        }
        // and we're out of here!
        return image
    }
}

