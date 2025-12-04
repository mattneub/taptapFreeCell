import UIKit
import QuickLook

protocol PreviewerType {
    func viewController(for stat: Stat) async -> UIViewController?
}

final class Previewer: PreviewerType {
    var previewImageURL : URL {
        return URL.temporaryDirectory.appendingPathComponent("Deal.png")
    }

    func viewController(for stat: Stat) async -> UIViewController? {
        let image = await UIImage.snapshot(for: stat)
        try? services.fileManager.removeItem(at: previewImageURL)
        do {
            try image.pngData()?.write(to: previewImageURL)
        } catch {
            return nil
        }
        let controller = QLPreviewController()
        controller.dataSource = self
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
