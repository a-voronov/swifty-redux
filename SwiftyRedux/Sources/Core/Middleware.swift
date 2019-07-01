/// Returns state.
public typealias GetState<State> = () -> State?

/// Dispatches action.
public typealias Dispatch = (Action) -> Void

/// [Middleware](https://redux.js.org/advanced/middleware) provides a third-party extension point between dispatching an action,
/// and the moment it reaches the reducer.
///
/// It allows you to perform side-effects and async tasks.
/// The best feature of middleware is that it's composable in a chain.
/// You can use multiple independent middleware in a single store without one knowing about another.
///
/// - Parameters:
///     - getState: Returns current state if store is alive, otherwise - nil.
///     - dispatch: Dispatches given action to the store. Performs asynchronously when used in store.
///         The action will actually travel the whole middleware chain again, including the current middleware.
///     - next: Dispatches given action further in the middleware chain. Performs synchronously when used in store.
///         Middleware can decide not to propagate action further by not calling `next` function,
///         however it's better if action travels the whole way back to the store.
/// - Returns: Dispatch function for the next middleware. Here you can sniff all actions that come from the store to the reducer.
///     And dispatch new ones based on what you receive.
///     The very last participant of this chain is store's reducer. Store takes care of handling all of this.
///
/// - Warning: Be careful, as this can cause an **infinite loop**:
///     ```
///     let middleware: Middleware<State> = createMiddleware { getState, dispatch, next in
///         return { action in
///             dispatch(action)
///         }
///     }
///     ```
public typealias Middleware<State> = (
    _ getState: @escaping GetState<State>,
    _ dispatch: @escaping Dispatch,
    _ next: @escaping Dispatch
) -> Dispatch

/// Chains array of middlewares into single middleware. Each middleware will be processed in the same order as it's stored in the array.
///
/// - Parameter middleware: Array of middleware to chain into single one.
/// - Returns: Resulting middleware
public func applyMiddleware<State>(_ middleware: [Middleware<State>]) -> Middleware<State> {
    return { getState, dispatch, next in
        return middleware
            // array is reversed to form a call-stack. Thus who's put there first, will process action last.
            .reversed()
            .reduce(next) { result, current in
                current(getState, dispatch, result)
            }
    }
}

/// Creates middleware which propagates action to the next one automatically right after current one handles action.
/// You'll need such behaviour in most cases.
///
/// - Parameters:
///     - middleware: Middleware without `next` argument.
///     - getState: Returns current state if store is alive, otherwise - nil.
///     - dispatch: Dispatches given action to the store. Performs asynchronously when used in store.
///         The action will actually travel the whole middleware chain again, including the current middleware.
/// - Returns: Resulting middleware
public func createFallThroughMiddleware<State>(
    _ middleware: @escaping (_ getState: @escaping GetState<State>, _ dispatch: @escaping Dispatch) -> Dispatch
) -> Middleware<State> {
    return { getState, dispatch, next in
        let current = middleware(getState, dispatch)
        return { action in
            current(action)
            return next(action)
        }
    }
}

/// Just and identity function for middleware.
/// Can be used to keep code consistent when creating different kinds of middleware.
///
/// - Parameter middleware: Any middleware.
/// - Returns: Same middleware without any changes made to it.
public func createMiddleware<State>(_ middleware: @escaping Middleware<State>) -> Middleware<State> {
    return middleware
}
