extension EndgameStateMachine {
    struct SecondPly: EndgameStateType {
        let index: Int
        let accumulatedLayouts: [Layout]
        let backtrackState: any EndgameStateType
        var helper: any EndgameHelperType = EndgameHelper()

        func nextState() -> (any EndgameStateType)? {
            guard var layout = accumulatedLayouts.last else {
                return nil
            }
            let initialLayout = layout
            print("second ply splat", index)
            helper.splat(layout: &layout, index: index)
            var newAccumulatedLayouts = accumulatedLayouts
            if layout != initialLayout {
                newAccumulatedLayouts.append(layout)
            }
            if layout.numberOfCardsRemaining == 0 {
                return OutcomeWin(accumulatedLayouts: newAccumulatedLayouts)
            }
            let nextState: any EndgameStateType = if index < 7 {
                SecondPly(
                    index: index + 1,
                    accumulatedLayouts: self.accumulatedLayouts, // as it came to us
                    backtrackState: backtrackState
                )
            } else {
                backtrackState
            }
            if layout == initialLayout {
                return nextState
            }
            return Autoplay2(
                accumulatedLayouts: newAccumulatedLayouts,
                backtrackState: nextState
            )
        }
    }
}
