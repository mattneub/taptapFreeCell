import Foundation

enum GameEffect: Equatable {
    case animate([Move], duration: Double)
    case confetti
    case removeConfetti
    case tint([LocationAndCard])
    case tintsOff
    case updateStopwatch(TimeInterval)
}
