import Foundation

enum GameEffect: Equatable {
    case confetti
    case removeConfetti
    case tint([LocationAndCard])
    case tintsOff
    case updateStopwatch(TimeInterval)
}
