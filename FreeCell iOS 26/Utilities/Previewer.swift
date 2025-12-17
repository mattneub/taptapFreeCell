import UIKit
import QuickLook

protocol PreviewerType {
    func viewController(for stat: Stat, source: UIView?) async -> UIViewController?
}

final class Previewer: NSObject, PreviewerType {
    var previewImageURL : URL {
        return URL.temporaryDirectory.appendingPathComponent("Deal.png")
    }

    /// Here we save off a weak ref to the source view, so we can return it in `transitionViewFor`.
    weak var source: UIView?

    func viewController(for stat: Stat, source: UIView?) async -> UIViewController? {
        self.source = source
        let image = await UIImage.snapshot(for: stat)
        try? services.fileManager.removeItem(at: previewImageURL)
        do {
            try image.pngData()?.write(to: previewImageURL)
        } catch {
            return nil
        }
        let controller = QLPreviewController()
        controller.dataSource = self
        controller.delegate = self
        return controller
    }
}

extension Previewer: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
        return self.previewImageURL as NSURL
    }
}

extension Previewer: QLPreviewControllerDelegate {
    func previewController(
        _ controller: QLPreviewController,
        transitionViewFor item: any QLPreviewItem
    ) -> UIView? {
        return source
    }
}
