import SwiftyRedux
import ReactiveSwift

/// [Epic](https://redux-observable.js.org/docs/basics/Epics.html) is a function which takes a stream of actions
/// and returns a stream of actions. Basically - async pipe. **Actions in, actions out.**
///
/// While you'll most commonly produce actions out in response to some action you received in, that's not actually a requirement.
/// Once you're inside your Epic, use any Observable patterns you desire as long as anything output from the final,
/// returned stream, is an action.
///
/// Epics run alongside the normal Redux dispatch channel, *after* the reducers have already received them –
/// so you cannot "swallow" an incoming action. Actions always run through your reducers **before** your Epics even receive them.
///
/// Inspired by [redux-observable](https://redux-observable.js.org) and built on top of
/// [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift).
///
/// - Parameters:
///     - actions: Signal of incoming actions that never fails.
///     - state: State read-only reactive property. Basically - stream of state updates + its current value.
/// - Returns: Signal of outcoming actions that never fails.
///
/// - Attention: In order to not fall into stack overflow when synchronously producing output actions,
///     we're using scheduler that does it asynchronously.
///     Thus it can break order sometimes in which actions should have been dispatched naturally.
///
///     For example, imagine we're sending these actions one after another in a row:
///     ```
///     dispatch(One())
///     dispatch(Two())
///     dispatch(Five())
///     ```
///     If we had an epic that sends actions `Three()` and `Four()` when it receives action `Two()`,
///     there would be no guarantee that they would be dispatched in a correct order:
///     ```
///     One(), Two(), Three(), Four(), Five()
///     ```
public typealias Epic<State> = (_ actions: Signal<SwiftyRedux.Action, Never>, _ state: Property<State>) -> Signal<SwiftyRedux.Action, Never>

/// Creates middleware with a single epic.
/// Epic will receive action only after it has travelled through other middlewares and reducers,
/// so that it can't "swallow" or delay it.
///
/// You'd basically use this function along with `combineEpics` to pass multiple epics as a middleware to the store.
///
/// - Parameter epic: Epic that should be wrapped into middleware.
/// - Returns: Middleware wrapping epic.
public func createEpicMiddleware<State>(_ epic: @escaping Epic<State>) -> Middleware<State> {
    return { getState, dispatch, next in
        guard let initialState = getState() else { return next }

        let queueScheduler = QueueScheduler(qos: .default, name: "swifty-redux.epic.queue-scheduler")
        let state = MutableProperty<State>(initialState)
        let (actionsSignal, actionsObserver) = Signal<SwiftyRedux.Action, Never>.pipe()

        epic(actionsSignal, Property(state))
            .observe(on: queueScheduler)
            .observeValues(dispatch)

        return { action in
            // Downstream middleware gets the action first,
            // which includes their reducers, so state is
            // updated before epics receive the action
            next(action)

            // It's important to update the `state` before we emit
            // the action because otherwise it would be stale
            guard let currentState = getState() else { return }

            state.value = currentState
            actionsObserver.send(value: action)
        }
    }
}

/// Combines many epics into a single one.
///
/// You'd basically use this function along with `createEpicMiddleware` to pass multiple epics as a middleware to the store.
///
/// - Parameter epics: Array of epics to combine.
/// - Returns: Combined epic.
public func combineEpics<State>(_ epics: [Epic<State>]) -> Epic<State> {
    return { actions, state in
        Signal.merge(epics.map { $0(actions, state) })
    }
}
