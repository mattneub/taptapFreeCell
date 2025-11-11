/// A Source is an object that holds a card or cards and will give you one on demand.
/// This allows us to demand a card from various layout entities in a uniform way.
protocol Source {
    var card: Card? { get }
    var cards: [Card] { get set }
    mutating func surrenderCard() -> Card
}

/// A Destination is an object that holds a card or cards and will accept on demand.
/// This allows us to hand a card to various layout entities in a uniform way.
protocol Destination {
    var card: Card? { get }
    var cards: [Card] { get set }
    mutating func accept(card: Card)
}
