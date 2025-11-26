import Foundation

protocol UserDefaultsType {
    func set(_: Any?, forKey: String)
    func data(forKey: String) -> Data?
    func bool(forKey: String) -> Bool
}

extension UserDefaults: UserDefaultsType {}
