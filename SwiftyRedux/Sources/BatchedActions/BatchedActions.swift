/// original: https://github.com/tshelburne/redux-batched-actions
/// Batching action and associated higher order reducer that enables batching subscriber notifications for an array of actions.

public protocol BatchedActions: Action {
    var actions: [Action] { get }
}

public struct BatchAction: BatchedActions {
    public let actions: [Action]

    public init(_ first: Action, _ rest: Action...) {
        self.actions = [first] + rest
    }
}

/// Handling bundled actions in reducer

public func enableBatching<State>(_ reducer: @escaping Reducer<State>) -> Reducer<State> {
    func batchingReducer(_ action: Action, _ state: State) -> State {
        guard let batchAction = action as? BatchedActions else {
            return reducer(action, state)
        }
        return batchAction.actions.reduce(state) { batchingReducer($1, $0) }
    }
    return batchingReducer
}

/// You can add a middleware to dispatch each of the bundled actions.
/// This can be used if other middlewares are listening for one of the bundled actions to be dispatched.
///
/// Note that `batchDispatchMiddleware` and `enableBatching` should not be used together
/// as `batchDispatchMiddleware` calls next on the action it receives, whilst also dispatching each of the bundled actions.

public func batchDispatchMiddleware<State>() -> Middleware<State> {
    func dispatchChildActions(_ getState: @escaping GetState<State>, _ dispatch: @escaping Dispatch, _ action: Action) {
        guard let batchAction = action as? BatchedActions else {
            return dispatch(action)
        }
        batchAction.actions.forEach { action in
            dispatchChildActions(getState, dispatch, action)
        }
    }

    return { getState, dispatch, next in
        return { action in
            guard let batchAction = action as? BatchedActions else {
                return next(action)
            }
            return dispatchChildActions(getState, dispatch, batchAction)
        }
    }
}
