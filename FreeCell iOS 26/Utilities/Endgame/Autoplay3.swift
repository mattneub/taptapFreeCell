extension EndgameStateMachine {
    struct Autoplay3: EndgameStateType {
        let accumulatedLayouts: [Layout]
        let backtrackState: any EndgameStateType
        var helper: any EndgameHelperType = EndgameHelper()

        func nextState() -> (any EndgameStateType)? {
            print("autoplay3")
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
            return backtrackState
        }
    }
}
