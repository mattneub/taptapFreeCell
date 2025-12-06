@testable import TTFreeCell
import Foundation

final class MockBundle: BundleType {
    var methodsCalled = [String]()
    var name: String?
    var ext: String?
    var subpath: String?
    var urlToReturn: URL?

    func url(forResource name: String?, withExtension ext: String?, subdirectory subpath: String?) -> URL? {
        methodsCalled.append(#function)
        self.name = name
        self.ext = ext
        self.subpath = subpath
        return urlToReturn
    }
}
