/// Simple value type uniting a location and internal index with the card that is located there.
struct LocationAndCard: Equatable, Hashable {
    let location: Location
    let internalIndex: Int
    let card: Card
}
