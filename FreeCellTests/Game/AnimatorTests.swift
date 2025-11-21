@testable import FreeCell
import Testing

struct AnimatorTests {
    @Test("animate: transforms layout pair into moves, sends to processor's presenter")
    func animate() async throws {
        enum Wrong: Error { case wrong }
        let processor = MockProcessor<GameAction, GameState, GameEffect>()
        let presenter = MockReceiverPresenter<GameEffect, GameState>()
        processor.presenter = presenter
        let subject = Animator(processor: processor)
        var layout1 = Layout()
        layout1.columns[0].cards = [
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .diamonds),
        ]
        layout1.columns[1].cards = [
            Card(rank: .ten, suit: .diamonds),
        ]
        layout1.columns[2].cards = [
            Card(rank: .ace, suit: .spades),
        ]
        var layout2 = Layout()
        layout2.columns[0].cards = [
            Card(rank: .ten, suit: .hearts),
        ]
        layout2.columns[1].cards = [
            Card(rank: .ten, suit: .diamonds),
            Card(rank: .nine, suit: .clubs), // the nine and the eight moved
            Card(rank: .eight, suit: .diamonds),
        ]
        layout2.foundations[0].cards = [
            Card(rank: .ace, suit: .spades), // the ace moved
        ]
        await subject.animate(oldLayout: layout1, newLayout: layout2, speed: .fast)
        let expectedMoves: [Move] = [
            // the nine of clubs moved from column 0 index 1 to column 1 index 1
            Move(
                source: LocationAndCard(
                    location: Location(category: .column, index: 0),
                    internalIndex: 1,
                    card: Card(rank: .nine, suit: .clubs)
                ),
                destination: LocationAndCard(
                    location: Location(category: .column, index: 1),
                    internalIndex: 1,
                    card: Card(rank: .nine, suit: .clubs)
                )
            ),
            // the eight of diamonds moved from column 0 index 2 to column 1 index 2
            Move(
                source: LocationAndCard(
                    location: Location(category: .column, index: 0),
                    internalIndex: 2,
                    card: Card(rank: .eight, suit: .diamonds)
                ),
                destination: LocationAndCard(
                    location: Location(category: .column, index: 1),
                    internalIndex: 2,
                    card: Card(rank: .eight, suit: .diamonds)
                )
            ),
            // the ace of spades moved from column 2 to foundation 0
            Move(
                source: LocationAndCard(
                    location: Location(category: .column, index: 2),
                    internalIndex: 0,
                    card: Card(rank: .ace, suit: .spades)
                ),
                destination: LocationAndCard(
                    location: Location(category: .foundation, index: 0),
                    internalIndex: 0,
                    card: Card(rank: .ace, suit: .spades)
                )
            ),
        ]
        let result = presenter.thingsReceived.first!
        guard case .animate(let moves, let duration) = result else {
            throw Wrong.wrong
        }
        #expect(moves.count == 3)
        #expect(moves.contains(expectedMoves[0]))
        #expect(moves.contains(expectedMoves[1]))
        #expect(moves.contains(expectedMoves[2]))
        #expect(duration == 0.1)
    }

    @Test("animate: if speed is no animation, does nothing")
    func animateNoAnimation() async {
        let processor = MockProcessor<GameAction, GameState, GameEffect>()
        let presenter = MockReceiverPresenter<GameEffect, GameState>()
        processor.presenter = presenter
        let subject = Animator(processor: processor)
        var layout1 = Layout()
        layout1.columns[0].cards = [
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .diamonds),
        ]
        layout1.columns[1].cards = [
            Card(rank: .ten, suit: .diamonds),
        ]
        layout1.columns[2].cards = [
            Card(rank: .ace, suit: .spades),
        ]
        var layout2 = Layout()
        layout2.columns[0].cards = [
            Card(rank: .ten, suit: .hearts),
        ]
        layout2.columns[1].cards = [
            Card(rank: .ten, suit: .diamonds),
            Card(rank: .nine, suit: .clubs), // the nine and the eight moved
            Card(rank: .eight, suit: .diamonds),
        ]
        layout2.foundations[0].cards = [
            Card(rank: .ace, suit: .spades), // the ace moved
        ]
        await subject.animate(oldLayout: layout1, newLayout: layout2, speed: .noAnimation)
        #expect(presenter.thingsReceived.isEmpty)
    }

    @Test("animate: if layouts are the same, returns empty moves list")
    func animateSameLayouts() async throws {
        enum Wrong: Error { case wrong }
        let processor = MockProcessor<GameAction, GameState, GameEffect>()
        let presenter = MockReceiverPresenter<GameEffect, GameState>()
        processor.presenter = presenter
        let subject = Animator(processor: processor)
        var layout1 = Layout()
        layout1.columns[0].cards = [
            Card(rank: .ten, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .eight, suit: .diamonds),
        ]
        layout1.columns[1].cards = [
            Card(rank: .ten, suit: .diamonds),
        ]
        layout1.columns[2].cards = [
            Card(rank: .ace, suit: .spades),
        ]
        await subject.animate(oldLayout: layout1, newLayout: layout1, speed: .fast)
        let result = presenter.thingsReceived.first!
        guard case .animate(let moves, _) = result else {
            throw Wrong.wrong
        }
        #expect(moves.isEmpty)
    }
}
