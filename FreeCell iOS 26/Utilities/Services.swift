import Foundation

final class Services {
    var fileManager: FileManagerType = FileManager.default
    var dateType: DateType.Type = Date.self
    var deckFactory: DeckFactoryType = DeckFactory()
    var lifetime: LifetimeType = Lifetime()
    var persistence: PersistenceType = Persistence()
    var stats: StatsType = Stats()
    var userDefaults: UserDefaultsType = UserDefaults.standard
}
