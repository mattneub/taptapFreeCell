enum StatsAction: Equatable {
    case initialData
    case resume(String)
    case totalChanged(total: Int, won: Int)
}
