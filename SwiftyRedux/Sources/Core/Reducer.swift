/// from https://redux.js.org/basics/reducers
/// Reducers specify how the application's state changes in response to actions sent to the store.
/// Remember that actions only describe what happened, but don't describe how the application's state changes.

/// It's the only place that can change application or domain state.
/// Reducers are pure functions that return new state depending on action and previous state.
/// They can be nested and combined together.
/// And it's better if they are split into smaller reducers that are focused on a small domain state.

public typealias Reducer<State> = (_ state: State, _ action: Action) -> State

public func combineReducers<State>(_ first: @escaping Reducer<State>, _ rest: Reducer<State>...) -> Reducer<State> {
    return { state, action in
        rest.reduce(first(state, action)) { state, reducer in
            reducer(state, action)
        }
    }
}
