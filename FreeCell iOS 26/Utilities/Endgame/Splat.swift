extension EndgameStateMachine {
    struct Splat: EndgameStateType {
        let initialLayout: Layout
        let index: Int
        var helper: any EndgameHelperType = EndgameHelper()
        
        func nextState() -> (any EndgameStateType)? {
            print("splat", index)
            var layout = initialLayout
            helper.splat(layout: &layout, index: index)
            let newAccumulatedLayouts = [layout]
            if layout.numberOfCardsRemaining == 0 {
                return OutcomeWin(accumulatedLayouts: newAccumulatedLayouts)
            }
            let nextState: any EndgameStateType = Shift(
                initialLayout: initialLayout,
                index: index
            )
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
