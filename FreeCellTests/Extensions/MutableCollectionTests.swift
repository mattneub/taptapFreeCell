import Testing
@testable import TTFreeCell

struct MutableCollectionTests {
    @Test("modifyEach: works as expected")
    func modifyEach() {
        struct Person: Equatable {
            var name: String
        }
        var people: [Person] = [
            Person(name: "manny"),
            Person(name: "moe"),
            Person(name: "jack"),
        ]
        people.modifyEach {
            $0.name = $0.name.uppercased()
        }
        #expect(people == [
            Person(name: "MANNY"),
            Person(name: "MOE"),
            Person(name: "JACK"),
        ])
    }
}
