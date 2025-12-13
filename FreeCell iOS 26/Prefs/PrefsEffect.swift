enum PrefsEffect: Equatable {
    case prefChanged(PrefKey, value: Bool)
    case speedChanged(index: Int)
}
