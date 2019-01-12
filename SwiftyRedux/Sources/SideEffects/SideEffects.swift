/// Plain side-effect middleware, that has access to store's state and dispatch method
/// Waits nothing in return, you just accept action and decide what to do next. Prety imperative.
/// Same as with Epics, SideEffects are run *after* reducers have received and processed the action,
/// so that, they can't "swallow" or delay it.

public typealias SideEffect<State> = (@escaping GetState<State>, @escaping Dispatch) -> Dispatch

public func createSideEffectMiddleware<State>(_ sideEffect: @escaping SideEffect<State>) -> Middleware<State> {
    return { getState, dispatch, next in
        let sideEffectDispatch = sideEffect(getState, dispatch)
        return { action in
            next(action)
            sideEffectDispatch(action)
        }
    }
}

public func combineSideEffects<State>(_ first: @escaping SideEffect<State>, _ rest: SideEffect<State>...) -> SideEffect<State> {
    let sideEffects = [first] + rest
    return { getState, dispatch in
        let dispatches = sideEffects.map { $0(getState, dispatch) }
        return { action in
            dispatches.forEach { dispatch in dispatch(action) }
        }
    }
}
