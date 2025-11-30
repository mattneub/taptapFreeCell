@testable import TTFreeCell
import Testing
import UIKit
import SnapshotTesting

private struct CardImageTests {
    let fileManager = MockFileManager()

    init() {
        CardImage.cardImageCache.removeAllObjects()
        services.fileManager = fileManager
    }

    @Test("image: if image is in cache, returns it without consulting file manager")
    func imageInCache() {
        let bundle = Bundle(for: MockFileManager.self)
        let imageURL = bundle.url(forResource: "JH", withExtension: "png")!
        let data = try! Data(contentsOf: imageURL)
        let image = UIImage(data: data)!
        CardImage.cardImageCache.setObject(image, forKey: "JH" as NSString)
        let card = Card(rank: .jack, suit: .hearts)
        let result = CardImage.image(for: card, scale: 2)
        #expect(result == image)
        #expect(fileManager.methodsCalled.isEmpty)
    }

    @Test("image: if image is not in cache but is in application support, returns it")
    func imageInApplicationSupport() {
        let bundle = Bundle(for: MockFileManager.self)
        let imageURL = bundle.url(forResource: "JH", withExtension: "png")!
        let data = try! Data(contentsOf: imageURL)
        let image = UIImage(data: data, scale: 2)!
        fileManager.applicationSupportURLtoReturn = imageURL
        let card = Card(rank: .jack, suit: .hearts)
        let result = CardImage.image(for: card, scale: 2)
        #expect(result.pngData()! == image.pngData()!)
        #expect(fileManager.methodsCalled == ["urlInApplicationSupport(name:)"])
    }

    @Test("image: if image is not in cache and not in application support, draws it, puts in cache, writes it to disk")
    func imageNowhere() throws {
        let tempURL = URL.temporaryDirectory.appending(component: "JH")
        fileManager.applicationSupportURLtoReturn = tempURL
        let card = Card(rank: .jack, suit: .hearts)
        let result = CardImage.image(for: card, scale: 2)
        let cached = try #require(CardImage.cardImageCache.object(forKey: "JH" as NSString))
        #expect(cached == result)
        let tempData = try #require(try? Data(contentsOf: tempURL))
        let tempImage = try #require(UIImage(data: tempData, scale: 2))
        #expect(tempImage.pngData() == result.pngData())
        assertSnapshot(of: result, as: .image) // and image looks right too :)
        try? FileManager.default.removeItem(at: tempURL) // clean up
    }

    @Test("loadImages: loads cache with images")
    func loadImages() {
        CardImage.loadImages()
        #expect(CardImage.cardImageCache.object(forKey: "JH" as NSString) != nil)
        #expect(CardImage.cardImageCache.object(forKey: "2C" as NSString) != nil)
        // okay, that's enough, it's full of images
        // and I'm not testing writing to disk because I don't actually care
    }
}
