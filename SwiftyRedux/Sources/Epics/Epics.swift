/// Inspired by https://redux-observable.js.org
/// Lightweight version which allows listening to and dispatching action on own serial queue scheduler.
/// It is a function which takes a stream of actions and returns a stream of actions. Basically - async pipe.
/// Epics run alongside the normal Redux dispatch channel, *after* the reducers have already received them –
/// so you cannot "swallow" an incoming action.
/// Actions always run through your reducers _before_ your Epics even receive them.

import ReactiveSwift

public typealias Epic<State> = (Signal<Action, Never>, Property<State>) -> Signal<Action, Never>

public func createEpicMiddleware<State>(_ epic: @escaping Epic<State>) -> Middleware<State> {
    return { getState, dispatch, next in
        guard let initialState = getState() else { return next }

        let queueScheduler = QueueScheduler(qos: .default, name: "redux.epic.queue-scheduler")
        let state = MutableProperty<State>(initialState)
        let (actionsSignal, actionsObserver) = Signal<Action, Never>.pipe()

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

public func combineEpics<State>(_ epics: [Epic<State>]) -> Epic<State> {
    return { actions, state in
        Signal.merge(epics.map { $0(actions, state) })
    }
}
