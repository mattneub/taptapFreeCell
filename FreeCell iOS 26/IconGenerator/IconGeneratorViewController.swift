
import UIKit

final class IconGeneratorViewController: UIViewController {
    @IBOutlet private weak var emptyCardView: CardView!
    @IBOutlet private weak var fullCardView: CardView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.subviews(ofType: UIImageView.self).first?.image = UIImage(named: "wallpaper.jpg")
        let w = self.emptyCardView.bounds.width
        let sz = CardImage.sourceImageSize
        let h = (w / sz.width * sz.height).rounded()
        CardView.baseSize = CGSize(width: w, height: h)
    }
    
    private var didLayout = false
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if !didLayout {
            didLayout = true
            self.emptyCardView.cards = []
            self.fullCardView.cards = [Card(rank: .ace, suit: .hearts)]
            emptyCardView.bounds.size.width = CardView.baseSize.width
            emptyCardView.bounds.size.height = CardView.baseSize.height
            fullCardView.bounds.size.width = CardView.baseSize.width
            fullCardView.bounds.size.height = CardView.baseSize.height
            emptyCardView.backgroundColor = nil
            fullCardView.backgroundColor = nil
            Task {
                try? await Task.sleep(for: .seconds(1))
                await emptyCardView.redraw()
                await fullCardView.redraw()
            }
        }
    }
}
