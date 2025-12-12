/// A PrefKey ties together a user-visible text and the behind the scenes key string
/// for communicating with user defaults A Pref ties together a PrefKey and its
/// Bool value.
struct Pref: Equatable {
    let key: PrefKey
    var value: Bool = false

    /// The canonical list of Prefs, the order and keys being dictated by PrefKey.
    static let list: [Pref] =  PrefKey.allCases.map { Pref(key: $0) }
}
