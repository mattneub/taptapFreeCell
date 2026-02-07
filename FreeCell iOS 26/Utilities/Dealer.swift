protocol DealerType: Actor {
    func newDeal() async -> Layout
}

/// Object that deals for us, ensuring that the deal it creates is not a duplicate of an
/// existing deal. This gets the knowledge of how to make a new deal off into a separate object.
/// It's an actor so that it can run in the background and take its time.
/// However, `layout.deal` runs on the main actor; that's a flaw.
actor Dealer: DealerType {
    /// Keep a record of all deals you return while the app is running. Thus, no matter what
    /// stats may say, you won't generate the same deal twice in a lifetime.
    var deals = Set<String>()

    /// Set of all deals that Stats thinks we have historically seen before.
    var stats = Set<String>()

    /// Deal, ensuring (by looking in stats) that this is not a duplicate of an existing deal.
    /// - Returns: Layout consisting of the new deal.
    func newDeal() async -> Layout {
        stats = await .init(services.stats.stats.keys)
        var layout = await Layout()
        let deckFactory = await services.deckFactory
        var deck: any DeckType = deckFactory.makeDeck()
        repeat {
            deck.shuffle()
            await layout.deal(deck)
        } while weHaveSeenThisDealBefore(layout)
        defer {
            deals.insert(layout.tableauDescription)
        }
        return layout
    }

    func weHaveSeenThisDealBefore(_ layout: Layout) -> Bool {
        let description = layout.tableauDescription
        return stats.contains(description) || deals.contains(description)
    }
}
