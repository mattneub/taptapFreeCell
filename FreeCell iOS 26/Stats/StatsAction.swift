enum StatsAction: Equatable {
    case delete(key: String)
    case initialData
    case mail(stat: Stat)
    case resume(key: String)
    case totalChanged(total: Int, won: Int)
}
