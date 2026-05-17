import Foundation

enum GameEffect: Equatable {
    case animate([Move], duration: Double)
    case confetti
    case hideInterface
    case removeConfetti
    case tint([LocationAndCard])
    case tintsOff
    case updateInterface
    case updateStopwatch(TimeInterval)
}
