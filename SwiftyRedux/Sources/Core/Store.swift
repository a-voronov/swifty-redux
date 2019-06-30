import Dispatch

/// [Store](https://redux.js.org/basics/store) is an object that holds the application's state tree.
///
/// Store has the following responsibilities:
/// - Holds application state;
/// - Allows access to state via `state`;
/// - Allows state to be updated via `dispatch(action)` or `dispatchAndWait(action)`;
/// - Registers listeners via `subscribe(observer)`;
/// - Handles unregistering of listeners via the `Disposable` returned by `subscribe(observer)`.
///
/// It's important to note that you'll only have a single store in a Redux application.
/// When you want to split your data handling logic, you'll use reducer composition instead of many stores.
///
/// There are many ways to share store inside your app:
/// - Keep global reference to it
/// - Inject it from top to bottom where it's needed
/// - Share only some of its functions like `dispatch(action)` and `subscribe(observer)`
///
/// You initialize store with initial state, main reducer and an array of middleware.
/// Store has its own queue for managing observers and state changes through reducers in a serial way.
public final class Store<State> {

    /// Main reducer
    private let reducer: Reducer<State>

    /// Synchronization read-write queue
    private let queue: ReadWriteQueue

    /// State updates observer and observable.
    /// - `Observer` is notified every time state changes and updates its `observable`.
    /// - `Observable` is used to update observers that subscribe to listen to state changes.
    private let (observable, observer): (Observable<State>, Observer<State>)

    /// Function that is used to dispatch an action.
    /// It passes action to the middleware, then - to the main reducer, and finally sets state provided by reducer and notifies observers.
    ///
    /// Action => Middleware => Reducers => Set State & Notify Observers
    private var dispatchFunction: Dispatch!

    /// Current state private property that we operate on inside store.
    private var currentState: State

    /// Current state.
    ///
    /// [State](https://redux.js.org/glossary#state) (also called the state tree) is a broad term,
    /// but in the Redux API it usually refers to the single state value that is managed by the store.
    /// It represents the entire state of a Redux application, which is often a deeply nested object.
    ///
    /// - Remark: Thread-safe.
    public var state: State {
        return queue.read { currentState }
    }

    /// Initializes store with initial state, main reducer and optionally - unique identifier and array of middleware.
    ///
    /// - Parameters:
    ///     - id: Unique identifier. Mostly used for internal queues labels and debugging purposes. Defaults to `"swifty-redux.store"`
    ///     - state: Initial state.
    ///     - reducer: Main reducer. Unlike middleware, reducers are already nested, thus it's not an array.
    ///     - middleware: Array of middlewares. No need to reduce them into single one before. Defaults to empty array.
    public init(id: String = "swifty-redux.store", state: State, reducer: @escaping Reducer<State>, middleware: [Middleware<State>] = []) {
        self.queue = ReadWriteQueue(label: "\(id).queue")
        self.currentState = state
        self.reducer = reducer

        (observable, observer) = Observable<State>.pipe(id: "\(id).observable")

        dispatchFunction = applyMiddleware(middleware)(
            { [weak self] in self?.state },
            { [weak self] in self?.dispatch($0) },
            { [weak self] in self?.defaultDispatch(from: $0) }
        )
    }

    /// Dispatches an action which travels through middleware to reducers and finally change state.
    /// This is the only way to trigger a state change.
    ///
    /// - Parameter action: Action to dispatch
    ///
    /// - Remark: Performs asynchronously.
    public func dispatch(_ action: Action) {
        queue.write {
            self.dispatchFunction(action)
        }
    }

    /// Dispatches an action which travels through middleware to reducers and finally change state.
    /// This is the only way to trigger a state change.
    ///
    /// - Parameter action: Action to dispatch
    ///
    /// - Remark: Performs synchronously.
    public func dispatchAndWait(_ action: Action) {
        queue.writeAndWait {
            self.dispatchFunction(action)
        }
    }

    /// Dispatch function that mutates state with main reducer and notifies observers
    ///
    /// - Parameter action: Action to dispatch
    ///
    /// - Remark: Performs synchronously.
    private func defaultDispatch(from action: Action) {
        queue.writeAndWait {
            self.currentState = self.reducer(self.currentState, action)
            self.observer.update(self.currentState)
        }
    }

    /// Subscribes a state update observer.
    /// It will be called any time an action is dispatched, and some part of the state tree may potentially have changed.
    /// You can stop listening to updates by calling `dispose()` on returned disposable.
    ///
    /// - Parameters:
    ///     - queue: A queue on which observer wants to receive updates. If `nil`, observer will be called on internal queue. Defaults to `nil`.
    ///     - includingCurrentState: If `true`, observer will immediately receive current state
    ///         (before creating and returning Disposable) and further updates as they appear.
    ///         If `false`, observer will only receive further updates as they appear. Defaults to `true`.
    ///     - observer: Observer callback that will receive new state after each update until it's manually disposed or store's dead.
    ///     - state: Current state right after it's changed.
    /// - Returns: Disposable to stop listening to updates.
    ///     Its `isDisposed` property will be `true` when store dies and cancels all subscriptions by itself.
    @discardableResult
    public func subscribe(on queue: DispatchQueue? = nil, includingCurrentState: Bool = true, observer: @escaping (_ state: State) -> Void) -> Disposable {
        let observer = Observer(queue: queue, update: observer)
        if includingCurrentState {
            observer.update(state)
        }
        return observable.subscribe(observer: observer)
    }
}
