import Foundation

final class Services {
    var fileManager: FileManagerType = FileManager.default
    var date: DateType.Type = Date.self
    var lifetime: LifetimeType = Lifetime()
    var persistence: PersistenceType = Persistence()
    var userDefaults: UserDefaultsType = UserDefaults.standard
}
