enum StatsAction: Equatable {
    case delete(key: String)
    case initialData
    case mail(stat: Stat)
    case resume(key: String)
    case snapshot(stat: Stat)
    case totalChanged(total: Int, won: Int)
}
