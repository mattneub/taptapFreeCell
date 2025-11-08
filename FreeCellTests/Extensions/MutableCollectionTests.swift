import Testing
@testable import FreeCell

struct MutableCollectionTests {
    @Test("modifyEach: works as expected")
    func modifyEach() {
        struct Person: Equatable {
            var name: String
        }
        var people: [Person] = [
            .init(name: "manny"),
            .init(name: "moe"),
            .init(name: "jack"),
        ]
        people.modifyEach {
            $0.name = $0.name.uppercased()
        }
        #expect(people == [
            .init(name: "MANNY"),
            .init(name: "MOE"),
            .init(name: "JACK"),
        ])
    }
}
