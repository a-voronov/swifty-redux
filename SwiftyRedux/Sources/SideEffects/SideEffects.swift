/// Side effect is a function that allows you read store's state, dispatch actions and receive actions.
/// You can perform any async logic here like making network calls, handling a socket connection or talking to a Database.
/// You can combine many side effects in a single middleware.
///
/// Inspired by [redux-observable](https://redux-observable.js.org).[Epics](https://redux-observable.js.org/docs/basics/Epics.html)
/// but have more imperative nature.
/// Same as Epics, side effects are run **after** reducers have received and processed the action,
/// so that, they can't "swallow" or delay it.
///
/// You'd use `combineSideEffects` along with `createSideEffectMiddleware` to pass multiple side effects as a middleware to the store.
///
///     let combinedSideEffect = combineSideEffects(
///         networkMonitoringSideEffect(),
///         databaseSideEffect(),
///         gRPCStreamingSideEffect()
///     )
///     let middleware = createSideEffectMiddleware(combinedSideEffect)
///
/// - Parameters:
///     - getState: Returns current state if store is alive, otherwise - nil.
///     - dispatch: Dispatches given action to the store. Performs asynchronously when used in store.
///         The action will travel the whole middleware chain again, including the current middleware and all the side effects.
/// - Returns: Dispatch function where side effect receives actions.
public typealias SideEffect<State> = (_ getState: @escaping GetState<State>, _ dispatch: @escaping Dispatch) -> Dispatch

/// Creates middleware with a single side effect.
/// Side effect will receive action only after it has travelled through other middlewares and reducers,
/// so that it can't "swallow" or delay it.
///
/// You'd basically use this function along with `combineSideEffects` to pass multiple side effects as a middleware to the store.
///
/// - Parameter sideEffect: Side effect that should be wrapped into middleware.
/// - Returns: Middleware wrapping side effect.
public func createSideEffectMiddleware<State>(_ sideEffect: @escaping SideEffect<State>) -> Middleware<State> {
    return { getState, dispatch, next in
        let sideEffectDispatch = sideEffect(getState, dispatch)
        return { action in
            next(action)
            sideEffectDispatch(action)
        }
    }
}

/// Combines many side effects into single one. Accepts more than one side effects, otherwise it doesn't make sense.
///
/// You'd basically use this function along with `createSideEffectMiddleware` to pass multiple side effects as a middleware to the store.
///
/// - Parameters:
///     - first: Initial side effect.
///     - second: Second side effect.
///     - rest: A variadic parameter of the rest of side effects to combine into one.
/// - Returns: Combined side effect.
public func combineSideEffects<State>(
    _ first: @escaping SideEffect<State>,
    _ second: @escaping SideEffect<State>,
    _ rest: SideEffect<State>...
) -> SideEffect<State> {
    let sideEffects = [first, second] + rest
    return { getState, dispatch in
        let dispatches = sideEffects.map { $0(getState, dispatch) }
        return { action in
            dispatches.forEach { dispatch in dispatch(action) }
        }
    }
}
