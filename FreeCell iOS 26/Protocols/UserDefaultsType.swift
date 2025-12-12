import Foundation

protocol UserDefaultsType {
    func set(_: Any?, forKey: String)
    func data(forKey: String) -> Data?
    func bool(forKey: String) -> Bool
    func integer(forKey: String) -> Int
    func double(forKey: String) -> Double
    func register(defaults: [String: Any])
}

extension UserDefaults: UserDefaultsType {}
