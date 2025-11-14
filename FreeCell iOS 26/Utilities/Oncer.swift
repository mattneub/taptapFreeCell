/// Utility object that helps us ensure that a given piece of code runs only once.
struct Oncer<T> {
    var done = false
    let whatToDo: (T) -> ()
    init(_ whatToDo: @escaping (T) -> ()) {
        self.whatToDo = whatToDo
    }
    mutating func doYourThing(_ what: T) throws {
        if done {
            throw OnceError.tooMany
        }
        done = true
        whatToDo(what)
    }
}

enum OnceError: Error {
    case notEnough
    case tooMany
}
