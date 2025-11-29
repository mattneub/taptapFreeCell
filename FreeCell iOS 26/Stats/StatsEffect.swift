enum StatsEffect: Equatable {
    case sort(StatsSorting)
    case totalChanged(total: Int, won: Int)
    case toggleMicrosofts
}
