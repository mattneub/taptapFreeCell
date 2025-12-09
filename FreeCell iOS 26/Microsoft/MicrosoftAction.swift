import Foundation

enum MicrosoftAction: Equatable {
    case cancel
    case deal
    case initialData
    case stepper(Double)
    case userTyped(Int)
}
