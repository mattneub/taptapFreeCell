enum StatsEffect: Equatable {
    case delete(row: Int)
    case sort(StatsSorting)
    case totalChanged(total: Int, won: Int)
    case toggleMicrosofts
}
