@testable import TTFreeCell
import Testing
import UIKit

struct GameViewMenuBuilderTests {
    @Test("menu is correctly built")
    func build() throws {
        let result = GameViewMenuBuilder().buildMenu()
        #expect(result.title == "")
        #expect(result.children.count == 5)
        do {
            let action = try #require(result.children[0] as? UIAction)
            #expect(action.title == "Rules")
            #expect(action.image == UIImage(systemName: "lightbulb"))
        }
        do {
            let action = try #require(result.children[1] as? UIAction)
            #expect(action.title == "About")
            #expect(action.image == UIImage(systemName: "questionmark.circle"))
        }
        do {
            let action = try #require(result.children[2] as? UIAction)
            #expect(action.title == "Statistics")
            #expect(action.image == UIImage(systemName: "pencil.and.list.clipboard"))
        }
        do {
            let action = try #require(result.children[3] as? UIAction)
            #expect(action.title == "Import / Export")
            #expect(action.image == UIImage(systemName: "arrow.up.arrow.down.circle"))
        }
        do {
            let action = try #require(result.children[4] as? UIAction)
            #expect(action.title == "Settings")
            #expect(action.image == UIImage(systemName: "gear"))
        }
    }
}
