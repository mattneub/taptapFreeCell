import UIKit

enum StatsAction: Equatable {
    case delete(key: String)
    case initialData
    case mail(stat: Stat)
    case resume(key: String)
    case showSnapshot(stat: Stat, source: UIView?)
    case totalChanged(total: Int, won: Int)
}
