/// [Actions](https://redux.js.org/basics/actions) are payloads of information that send data from your application to your store.
/// They are the only source of information for the store.
///
/// An action is a plain object that represents an intention to change the state.
/// Actions are the only way to get data into the store.
/// Any data, whether from UI events, network callbacks, or other sources such as WebSockets needs to eventually be dispatched as actions.
///
/// You send them to the store using `store.dispatch(action)`.
public protocol Action {}
