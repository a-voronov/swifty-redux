/// [Reducers](https://redux.js.org/basics/reducers) specify how the application's state changes in response to actions sent to the store.
/// Remember that actions only describe what happened, but don't describe how the application's state changes.
///
/// It's the only place that can change application or domain state.
/// Reducers are pure functions (there should be **no side effects**) that return new state depending on action and previous state.
/// They can be nested and combined together.
/// And it's better if they are split into smaller reducers that are focused on a small domain state.
///
/// - Parameters:
///     - state: Current state.
///     - action: Incoming action.
/// - Returns: New state as a result of applying action to the current state.
public typealias Reducer<State> = (_ state: State, _ action: Action) -> State
