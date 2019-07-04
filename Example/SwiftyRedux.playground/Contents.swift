/*:
 > # IMPORTANT: To use `SwiftyRedux.playground`, please:

 1. Open `SwiftyRedux.xcworkspace`
 1. Build `SwiftyRedux-Example` scheme
 1. Finally open the `SwiftyRedux.playground`
 1. Choose `View > Show Debug Area`
 */

import Foundation
import PlaygroundSupport
import SwiftyRedux

PlaygroundPage.current.needsIndefiniteExecution = true

// MARK: - State

struct MainState {
    var counter: Int

    static let initial = MainState(counter: 0)
}

// MARK: - Actions

enum Operations {
    struct Increment: Action { }
    struct Decrement: Action { }
}

// MARK: - Reducer

let mainReducer: Reducer<MainState> = { state, action in
    switch action {
    case is Operations.Increment:
        return updating(state) { $0.counter += 1 }
    case is Operations.Decrement:
        return updating(state) { $0.counter -= 1 }
    default:
        return state
    }
}

// MARK: - Middleware

let loggingMiddleware: Middleware<MainState> = createMiddleware { getState, dispatch, next in
    return { action in
        guard let oldState = getState() else { return }
        print("[OLD ➡️]: \(oldState)")
        print("[MSG ✅]: \(action)")
        next(action)
        guard let newState = getState() else { return }
        print("[NEW ⬅️]: \(newState)\n")
    }
}

// MARK: - Store

let store = Store(state: MainState.initial, reducer: mainReducer, middleware: [batchDispatchMiddleware(), loggingMiddleware])

// MARK: - Run

// will send current and further state updates once started
let uniqueEvenCounter = store.stateProducer()
    // focus on counter
    .map(\.counter)
    // filter only even values
    .filter { $0.isMultiple(of: 2) }
    // skip repeating in a row counter values
    .skipRepeats()

// counter: 1
store.dispatch(Operations.Increment())

// notice that we don't receive 0 counter here even though it's even value
// that's because we start observing state after its counter value is already 1
uniqueEvenCounter.start { counter in
    // see how this message is printed before "[NEW ...]" but after "[MSG ...]"
    // this is because the last `next` in middleware chain
    // is a function that applies reducer to the current state, updates state with its result and notifies observers,
    // and only then we get new updated state and log it with "[NEW ...]" message
    print("🎲 Unique Even Counter: \(counter)")
}

// counter: 2
store.dispatch(Operations.Increment())

// counter: 3
store.dispatch(Operations.Increment())

// counter: 2
// see, we don't print "Unique Even Counter" as its previous even value was also 2
store.dispatch(Operations.Decrement())

// notice how actions are split into single actions by `batchDispatchMiddleware`,
// and BatchAction is logged afterwards and not handled by reducer
store.dispatch(BatchAction(
    // counter: 3
    Operations.Increment(),
    // counter: 4
    Operations.Increment()
))

// counter: 3
store.dispatch(Operations.Decrement())

// counter: 2
// now we receive 2 again, as previous was counter value was 4, even though we've already had 2 few steps before
store.dispatch(Operations.Decrement())
