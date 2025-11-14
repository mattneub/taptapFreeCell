import Foundation

final class GameProcessor: Processor {
    weak var coordinator: (any RootCoordinatorType)?

    weak var presenter: (any ReceiverPresenter<GameEffect, GameState>)?

    var state = GameState()

    func receive(_ action: GameAction) async {
        switch action {
        case .autoplay:
            await autoplay()
        case .deal:
            var deck = Deck()
            deck.shuffle()
            state.layout.deal(deck)
            state.firstTapLocation = nil
            state.enablements = state.baseEnablements
            await presenter?.present(state)
        case .hint:
            state.firstTapLocation = nil
            state.enablements = hintEnablements()
            await presenter?.present(state)
        case .tapBackground:
            state.firstTapLocation = nil
            state.enablements = state.baseEnablements
            await presenter?.present(state)
        case .tapped(let tap):
            if state.firstTapLocation == nil {
                await handleFirstTap(tap)
            } else {
                await handleSecondTap(tap)
            }
        }
    }

    func playToFoundationIfSafeAndPossible(location: Location) -> Bool {
        if let card = state.layout.card(at: location) {
            if card.canGoOn(state.layout.foundations) {
                if !state.layout.mightNeed(card: card) {
                    let card = state.layout.surrenderCard(from: location)
                    state.layout.foundations.accept(card: card)
                    return true
                }
            }
        }
        return false
    }

    func autoplay() async {
        var moved = false
        let locations: [Location] = (
            (0..<8).map { Location(category: .column, index: $0) } +
            (0..<4).map { Location(category: .freeCell, index: $0) }
        )
        repeat {
            moved = false
            for location in locations {
                if playToFoundationIfSafeAndPossible(location: location) {
                    moved = true
                }
            }
        } while moved
        state.firstTapLocation = nil
        state.enablements = state.baseEnablements
        await presenter?.present(state)
    }

    func handleFirstTap(_ location: Location) async {
        guard
            // tap on an empty card is not a valid first tap
            state.layout.card(at: location) != nil,
            // tap on a foundation is not a valid first tap
            location.category != .foundation,
            // TODO: should probably make this a separate pref
            // tap on a safe autoplayable just plays it
            !playToFoundationIfSafeAndPossible(location: location)
        else {
            // in all those cases, return to a neutral situation, waiting for first tap
            state.firstTapLocation = nil
            state.enablements = state.baseEnablements
            await presenter?.present(state)
            return
        }
        // only one move is possible and pref is on
        if state.unambiguousMove {
            if let _ = try? await unambiguousMove(location: location) {
                return // we have made the move completely, all done
            }
        }
        // this is a first tap and we must wait for the second tap, so
        // store it, and respond by highlighting / enabling
        state.firstTapLocation = location
        state.enablements = firstTapEnablements(for: location)
        await presenter?.present(state)
    }

    func firstTapEnablements(for location: Location) -> [Location: GameState.Enablement] {
        guard state.showDestinations, let card = state.layout.card(at: location) else {
            return state.baseEnablements
        }
        // okay, we _are_ showing destinations
        // begin by _assuming_ that all slots are disabled
        var result = state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
        // now enable those that should be enabled
        switch location.category {
        case .foundation:
            fatalError("this cannot happen")
        case .freeCell:
            if card.canGoOn(state.layout.foundations) { // if can go on _any_ foundation, illuminate _all_
                (0..<4).forEach {
                    result[.init(category: .foundation, index: $0)] = .enabled
                }
            }
            (0..<8).forEach { // if can go on a column, illuminate that one
                if card.canGoOn(state.layout.columns[$0]) {
                    result[.init(category: .column, index: $0)] = .enabled
                }
            }
        case .column:
            if state.layout.numberOfEmptyFreeCells > 0 { // if can go on _any_ freecell, illuminate _all_
                (0..<4).forEach {
                    result[.init(category: .freeCell, index: $0)] = .enabled
                }
            }
            if card.canGoOn(state.layout.foundations) { // if can go on _any_ foundation, illuminate _all_
                (0..<4).forEach {
                    result[.init(category: .foundation, index: $0)] = .enabled
                }
            }
            (0..<8).forEach { // if can be moved to a column, illuminate that one
                if state.layout.howManyCardsCanMoveLegally(
                    from: location.index,
                    to: $0,
                    sequenceMoves: state.sequenceMoves,
                    supermoves: state.supermoves
                ) > 0 {
                    result[.init(category: .column, index: $0)] = .enabled
                }
            }
        }
        return result
    }

    func hintEnablements() -> [Location: GameState.Enablement] {
        var result = state.baseEnablements.mapValues { _ in GameState.Enablement.disabled }
        // enable all free cells and columns that can go on a _nonempty_ foundation or column
    freecells:
        for source in (0..<4) {
        thisFreeCell:
            if let card = state.layout.freeCells[source].card {
                if card.canGoOn(state.layout.foundations) {
                    result[.init(category: .freeCell, index: source)] = .enabled
                    continue freecells
                }
                for dest in (0..<8) {
                    if card.canGoOn(state.layout.columns[dest]) && !state.layout.columns[dest].isEmpty {
                        result[.init(category: .freeCell, index: source)] = .enabled
                        continue freecells
                    }
                }
            }
        }
    columns:
        for source in (0..<8) {
            if let card = state.layout.columns[source].card {
                if card.canGoOn(state.layout.foundations) {
                    result[.init(category: .column, index: source)] = .enabled
                    continue columns
                }
            }
            for dest in (0..<8) {
                if dest != source && !state.layout.columns[dest].isEmpty {
                    if state.layout.howManyCardsCanMoveLegally(
                        from: source,
                        to: dest,
                        sequenceMoves: state.sequenceMoves,
                        supermoves: state.supermoves
                    ) > 0 {
                        result[.init(category: .column, index: source)] = .enabled
                        continue columns
                    }
                }
            }
        }
        return result
    }

    func unambiguousMove(location: Location) async throws {
        // look for all possible move destinations for location; if there is exactly one,
        // make that move, else throw
        var destination: Location?
        // gateway so that an attempt to set an already set `destination` will throw
        var oncer = Oncer {
            destination = $0
        }
        // now all we have to do is call `oncer.doYourThing()` and never set `destination` directly
        switch location.category {
        case .foundation:
            fatalError("this cannot happen")
        case .freeCell:
            if let card = state.layout.card(at: location) {
                if card.canGoOn(state.layout.foundations) {
                    try oncer.doYourThing(
                        .init(
                            category: .foundation,
                            index: state.layout.indexOfFoundation(for: card.suit)
                        )
                    )
                }
                for index in 0..<8 {
                    if card.canGoOn(state.layout.columns[index]) {
                        try oncer.doYourThing(
                            .init(
                                category: .column,
                                index: index
                            )
                        )
                    }
                }
            }
        case .column:
            if let card = state.layout.card(at: location) {
                if card.canGoOn(state.layout.foundations) {
                    try oncer.doYourThing(
                        .init(
                            category: .foundation,
                            index: state.layout.indexOfFoundation(for: card.suit)
                        )
                    )
                }
                if let index = state.layout.indexOfFirstEmptyFreeCell {
                    try oncer.doYourThing(
                        .init(
                            category: .freeCell,
                            index: index
                        )
                    )
                }
                for index in (0..<8) {
                    if index != location.index && state.layout.howManyCardsCanMoveLegally(
                        from: location.index,
                        to: index,
                        sequenceMoves: state.sequenceMoves,
                        supermoves: state.supermoves
                    ) > 0 {
                        try oncer.doYourThing(
                            .init(
                                category: .column,
                                index: index
                            )
                        )
                    }
                }
            }
        }
        guard let destination else {
            throw OnceError.notEnough // we didn't find _any_ moves!
        }
        // Pretend that `location` was the first tap and `destination` is the second!
        state.firstTapLocation = location
        await handleSecondTap(destination)
    }

    func handleSecondTap(_ secondTapLocation: Location) async {
        guard let firstTapLocation = state.firstTapLocation else {
            return // shouldn't happen
        }
        guard let card = state.layout.card(at: firstTapLocation) else {
            return // shouldn't happen
        }
        switch secondTapLocation.category {
        case .foundation:
            // doesn't matter which foundation was tapped; if it can move, move it
            if card.canGoOn(state.layout.foundations) {
                let card = state.layout.surrenderCard(from: firstTapLocation)
                state.layout.foundations.accept(card: card)
            }
        case .freeCell:
            // doesn't matter which free cell was tapped; if it can move, move to first empty
            guard firstTapLocation.category == .column else {
                break // only a column can be moved to a free cell
            }
            guard let targetIndex = state.layout.indexOfFirstEmptyFreeCell else {
                break // we need a free cell to move to
            }
            let card = state.layout.surrenderCard(from: firstTapLocation)
            state.layout.freeCells[targetIndex].accept(card: card)
        case .column:
            switch firstTapLocation.category {
            case .foundation: break // shouldn't happen
            case .freeCell:
                if card.canGoOn(state.layout.columns[secondTapLocation.index]) {
                    let card = state.layout.surrenderCard(from: firstTapLocation)
                    state.layout.columns[secondTapLocation.index].accept(card: card)
                }
            case .column:
                let number = state.layout.howManyCardsCanMoveLegally(
                    from: firstTapLocation.index,
                    to: secondTapLocation.index,
                    sequenceMoves: state.sequenceMoves,
                    supermoves: state.supermoves
                )
                if number > 0 {
                    state.layout.columns[firstTapLocation.index].cards.suffix(number).forEach {
                        state.layout.columns[secondTapLocation.index].accept(card: $0)
                    }
                    state.layout.columns[firstTapLocation.index].cards.removeLast(number)
                }
            }
        }
        state.firstTapLocation = nil
        state.enablements = state.baseEnablements
        await presenter?.present(state)
        if state.autoplay {
            await autoplay()
        }
    }
}
