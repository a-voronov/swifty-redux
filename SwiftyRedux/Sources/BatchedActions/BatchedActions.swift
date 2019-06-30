/// [Batched action](https://github.com/tshelburne/redux-batched-actions) is an action that combines multiple actions.
/// Multiple batched actions can be combined as well as they conform to `Action` protocol.
public protocol BatchedActions: Action {

    /// Array of any combined actions.
    var actions: [Action] { get }
}

/// `BatchedActions` implementation. Should be initialized with one or more actions.
public struct BatchAction: BatchedActions {

    /// Array of any combined actions.
    public let actions: [Action]

    /// Initializes batch action with one or more actions.
    ///
    /// - Parameters:
    ///     - first: First action.
    ///     - rest: Rest of the actions variadic parameter.
    public init(_ first: Action, _ rest: Action...) {
        self.actions = [first] + rest
    }
}

/// Upgrades reducer to handle batched actions by splitting them into single actions no matter how deeply nested they are.
///
/// Example:
///
///     BatchAction(
///         One(),
///         BatchAction(
///             BatchAction(
///                 Two(),
///                 Three()
///             ),
///             Four()
///         ),
///         Five()
///     )
///
/// Will be handled in this order:
///
///     One(), Two(), Three(), Four(), Five()
///
/// - Parameter reducer: Reducer that should be upgraded.
/// - Returns: Upgraded reducer.
///
/// - Important: Note that `batchDispatchMiddleware` and `enableBatching` should not be used together
///     as `batchDispatchMiddleware` calls next on the action it receives, whilst also dispatching each of the bundled actions.
public func enableBatching<State>(_ reducer: @escaping Reducer<State>) -> Reducer<State> {
    func batchingReducer(_ state: State, _ action: Action) -> State {
        guard let batchAction = action as? BatchedActions else {
            return reducer(state, action)
        }
        return batchAction.actions.reduce(state, batchingReducer)
    }
    return batchingReducer
}

/// Middleware that dispatches batched actions by splitting them into single actions no matter how deeply nested they are.
///
/// Example:
///
///     BatchAction(
///         One(),
///         BatchAction(
///             BatchAction(
///                 Two(),
///                 Three()
///             ),
///             Four()
///         ),
///         Five()
///     )
///
/// Will dispatch actions in this order:
///
///     One(), Two(), Three(), Four(), Five()
///
/// - Returns: Middleware that intercepts batched actions and dispatch single actions out of them.
///
/// - Important: Note that `batchDispatchMiddleware` and `enableBatching` should not be used together
///     as `batchDispatchMiddleware` calls next on the action it receives, whilst also dispatching each of the bundled actions.
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
            if let batchAction = action as? BatchedActions {
                dispatchChildActions(getState, dispatch, batchAction)
            }
            return next(action)
        }
    }
}
