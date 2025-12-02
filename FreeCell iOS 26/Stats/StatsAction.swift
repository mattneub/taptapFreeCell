enum StatsAction: Equatable {
    case delete(key: String)
    case initialData
    case resume(key: String)
    case totalChanged(total: Int, won: Int)
}
