import UIKit

extension UIImage {
    /// Generate an image of the dealt initial layout of the given Stat. This is a lot simpler
    /// than you might suppose, because we just need eight card views and they will draw the
    /// columns for us. We just position those card views in a row across the top of
    /// a view, and then render that.
    static func snapshot(for stat: Stat) async -> UIImage {
        let cardSize = CardView.baseSize // the size at which CardView will draw itself
        let space = 4
        let width = cardSize.width * 8 + CGFloat(space) * 9
        let size = CGSize(width: width, height: cardSize.height * 5)
        let view = UIView(frame: CGRect(origin: .zero, size: size))
        let imageView = UIImageView(image: UIImage(named: "wallpaper.jpg"))
        imageView.frame = view.bounds
        view.addSubview(imageView)
        for index in 0..<8 {
            let cardView = CardView(location: Location(category: .column, index: index))
            cardView.frame = CGRect(
                x: cardSize.width * CGFloat(index) + CGFloat(space * (index + 1)),
                y: CGFloat(space),
                width: cardSize.width,
                height: cardSize.height
            )
            view.addSubview(cardView)
            cardView.cards = stat.initialLayout.columns[index].cards
            await cardView.redraw()
        }
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        return renderer.image { context in
            view.layer.render(in: context.cgContext)
        }
    }
}
