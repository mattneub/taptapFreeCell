import UIKit
@testable import TTFreeCell

final class MockMenuBuilderWrapper: MenuBuilderWrapper {
    var thingsInserted = [UIMenu.Identifier: [UIMenuElement]]()
    override func insertElements(_ insertedElements: [UIMenuElement], atStartOfMenu siblingIdentifier: UIMenu.Identifier) {
        thingsInserted[siblingIdentifier] = insertedElements
    }
}
