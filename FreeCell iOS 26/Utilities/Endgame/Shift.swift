extension EndgameStateMachine {
    struct Shift: EndgameStateType {
        let initialLayout: Layout
        let index: Int
        var helper: any EndgameHelperType = EndgameHelper()

        func nextState() -> (any EndgameStateType)? {
            print("shift", index)
            var layout = initialLayout
            helper.shift(layout: &layout, index: index)
            let newAccumulatedLayouts = [layout]
            if layout.numberOfCardsRemaining == 0 {
                return OutcomeWin(accumulatedLayouts: newAccumulatedLayouts)
            }
            let nextState: any EndgameStateType = if index < 7 {
                Splat(
                    initialLayout: initialLayout,
                    index: index + 1
                )
            } else {
                OutcomeLose()
            }
            if layout == initialLayout {
                return nextState
            }
            return Autoplay(
                accumulatedLayouts: newAccumulatedLayouts,
                backtrackState: nextState
            )
        }
    }
}
