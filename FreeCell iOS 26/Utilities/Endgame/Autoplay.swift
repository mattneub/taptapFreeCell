extension EndgameStateMachine {
    struct Autoplay: EndgameStateType {
        let accumulatedLayouts: [Layout]
        let backtrackState: any EndgameStateType
        var helper: any EndgameHelperType = EndgameHelper()

        func nextState() -> (any EndgameStateType)? {
            print("autoplay")
            guard var layout = accumulatedLayouts.last else {
                return nil
            }
            let initialLayout = layout
            helper.autoplay(layout: &layout)
            var newAccumulatedLayouts = accumulatedLayouts
            if layout != initialLayout {
                newAccumulatedLayouts.append(layout)
            }
            if layout.numberOfCardsRemaining == 0 {
                return OutcomeWin(accumulatedLayouts: newAccumulatedLayouts)
            }
            return SecondPly(
                index: 0,
                accumulatedLayouts: newAccumulatedLayouts,
                backtrackState: backtrackState
            )
        }
    }
}
