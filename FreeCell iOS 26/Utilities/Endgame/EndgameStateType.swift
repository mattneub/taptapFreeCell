/// A state in our state machine is merely a type that knows how to generate the next state.
protocol EndgameStateType {
    func nextState() -> (any EndgameStateType)?
}

/*
 Rule for writing a state machine state is that a state should be given at initialization time
 exactly the information it needs in order to construct and return the next state. And that's all.

 Our endgame state machine works like this. At the bottom level, we are cycling thru the column
 indexes 0 thru 7, calling Splat and Shift, like this:

 * Splat(index: 0)
 * Shift(index: 0)
 * Splat(index: 1)
 * Shift(index: 1)
 * ...
 * Splat(index: 7)
 * Shift(index: 7)

 If we reach Shift(index: 7) because we have not found a win, we return OutcomeLose.

 Each Splat or Shift performs a splat or shift on the layout it is handed at the outset (its
 `initialLayout`). If that does nothing to the layout, we proceed to next state in the column
 of bottom level states shown above. But if it does something, we go a level deeper, which is
 Autoplay, handing it our next bottom level state as a backtrack state:

 * Splat(index: 1) -> Autoplay(backtrack: Shift(index: 1)
 * Shift(index: 1)

 Autoplay does a round of autoplay on the layout, and without regard to whether it accomplishes
 anything, proceeds to the next level deeper, which is SecondPly:

 * Splat(index: 1) -> Autoplay -> SecondPly(index: 0, backtrack: Shift(index: 1))
 * Shift(index: 1)

 SecondPly tries a splat on every column index 0 thru 7; if that does nothing, it goes on to the
 next column index, and if the last column index does nothing, it backtracks:

 * Splat(index: 1) -> Autoplay -> SecondPly(index: 0, backtrack: Shift(index: 1))
 *                                SecondPly(index: 1, backtrack: Shift(index: 1))
 *                                ...
 *                                SecondPly(index: 7, backtrack: Shift(index: 1))
 * Shift(index: 1)

 If SecondPly does have an effect on the layout it was handed, we go on to the level deeper, which
 is another round of autoplay, Autoplay2.

 * ... -> SecondPly(index: 1, backtrack: Shift(index: 1)) -> Autoplay2(backtrack: SecondPly(index: 2))

 If Autoplay2 finds we have not won the game, it proposes to backtrack — but first it looks at
 _how close_ we are to a win. If we are close enough to make a third ply worth while, it goes a level
 deeper, to a ThirdPly.

 ThirdPly behaves just like SecondPly: it does a splat, and either goes on to the next ThirdPly
 column index, or goes a level deeper to Autoplay3.

 Autoplay 3 performs a round of autoplay and either wins or backtracks.

 Every state, after performing its action on the layout it was handed, checks to see whether we
 have achieved a win. If so, it returns OutcomeWin, handing it the entire list of distinct layouts
 accumulated as we moved deeper into the chain. Thus, for example, if all six depths (Splat,
 Autoplay, SecondPly, Autoplay2, ThirdPly, Autoplay3) changed the layout and if Autoplay3 wins,
 it hands OutcomeWin a list of all six layouts generated along the way. To accomplish this,
 every state hands the accumulated list to the next layout along the depth chain.
 */
