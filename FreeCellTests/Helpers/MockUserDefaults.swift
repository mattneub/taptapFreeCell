import Foundation
@testable import TTFreeCell

final class MockUserDefaults: UserDefaultsType {
    var methodsCalled = [String]()
    var thingsSet = [String: Any?]()
    var thingsToReturn = [String: Any?]()

    func set(_ thing: Any?, forKey: String) {
        methodsCalled.append(#function)
        thingsSet[forKey] = thing
    }
    
    func data(forKey: String) -> Data? {
        methodsCalled.append(#function)
        return thingsToReturn[forKey] as? Data
    }
}
