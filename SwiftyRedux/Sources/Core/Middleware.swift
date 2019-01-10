/// from https://redux.js.org/advanced/middleware
/// It provides a third-party extension point between dispatching an action, and the moment it reaches the reducer.
/// People use Redux middleware for logging, crash reporting, talking to an asynchronous API, routing, and more.

/// Middleware allows you to perform side-effects and async tasks.
/// The best feature of middleware is that it's composable in a chain.
/// You can use multiple independent middleware in a single project without each one knowing about another.
/// It takes `getState` and `dispatch` functions from the store, and `next` function to pass action to the next middleware in the chain.
/// Result is a new `next` function that will be used in the next middleware.
/// The very last participant of this chain is store reducer. Store takes care of handling this.
///
/// You use `dispatch` function if you want to dispatch any kind of action from the middleware to the store,
/// The action will actually travel the whole middleware chain again, including the current middleware.
///
/// Middleware can decide not to propagate action further by not calling `next` function,
/// However it's better if action travels the whole way back to the store.
///
/// Note: be carefull, as this will cause an infinite loop
/// ```
/// let middleware: Middleware<State> = createMiddleware { getState, dispatch, next in
///     return { action in
///         dispatch(action)
///     }
/// }
/// ```

public typealias GetState<State> = () -> State?
public typealias Dispatch = (Action) -> Void

public typealias Middleware<State> = (
    _ getState: @escaping GetState<State>,
    _ dispatch: @escaping Dispatch,
    _ next: @escaping Dispatch
) -> Dispatch

public func applyMiddleware<State>(_ middleware: [Middleware<State>]) -> Middleware<State> {
    return { getState, dispatch, next in
        return middleware
            .reversed()
            .reduce(next) { result, current in
                current(getState, dispatch, result)
            }
    }
}

public func createFallThroughMiddleware<State>(_ middleware: @escaping (@escaping GetState<State>, @escaping Dispatch) -> Dispatch) -> Middleware<State> {
    return { getState, dispatch, next in
        let current = middleware(getState, dispatch)
        return { action in
            current(action)
            return next(action)
        }
    }
}

public func createMiddleware<State>(middleware: @escaping Middleware<State>) -> Middleware<State> {
    return middleware
}
