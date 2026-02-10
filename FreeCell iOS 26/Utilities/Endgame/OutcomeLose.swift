extension EndgameStateMachine {
    struct OutcomeLose: EndgameStateType {
        func nextState() -> (any EndgameStateType)? {
            print("lose")
            return nil
        }
    }
}
