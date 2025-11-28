import Foundation

final class Services {
    var fileManager: any FileManagerType = FileManager.default
    var dateType: any DateType.Type = Date.self
    var deckFactory: any DeckFactoryType = DeckFactory()
    var lifetime: any LifetimeType = Lifetime()
    var persistence: any PersistenceType = Persistence()
    var stats: any StatsType = Stats()
    var userDefaults: any UserDefaultsType = UserDefaults.standard
}
