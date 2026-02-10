extension EndgameStateMachine {
    struct OutcomeWin: EndgameStateType {
        let accumulatedLayouts: [Layout]
        
        func nextState() -> (any EndgameStateType)? {
            print("win")
            return nil
        }
    }
}
