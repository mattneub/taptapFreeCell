/// A Move is a description of the fate of a single card, by uniting two locations and internal
/// indexes. We already have a struct that expresses that unity — the LocationAndCard. So we
/// use that.
struct Move: Equatable {
    let source: LocationAndCard
    let destination: LocationAndCard
}
