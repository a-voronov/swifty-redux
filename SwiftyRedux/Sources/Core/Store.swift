import Dispatch

/// from https://redux.js.org/basics/store
/// The store has the following responsibilities:
///  • Holds application state;
///  • Allows access to state via `state`;
///  • Allows state to be updated via `dispatch(action)`;
///  • Registers listeners via `subscribe(observer)`;
///  • Handles unregistering of listeners via the `Disposable` returned by subscribe(observer).
/// It's important to note that you'll only have a single store in a Redux application.
/// When you want to split your data handling logic, you'll use reducer composition instead of many stores.

/// You initialize store with initial state, main reducer and an array of middleware.
/// Store has its own queue for managing observers and state changes through reducers in a serial way.
/// If you want to modify the way you observe state updates, use `observe()` to operate on observer and then call its `subscribe` method.
/// Keep a global reference to store somewhere in AppDelegate or just as a global value, as you'll need it to subscibe to state changes and dispatch actions.

public final class Store<State> {
    private let reducer: Reducer<State>
    private let queue: ReadWriteQueue
    private let (observable, observer): (Observable<State>, Observer<State>)
    private var dispatchFunction: Dispatch!

    private var currentState: State
    public var state: State {
        return queue.read { currentState }
    }

    public init(id: String = "redux.store", state: State, reducer: @escaping Reducer<State>, middleware: [Middleware<State>] = []) {
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

    public func dispatch(_ action: Action) {
        queue.write {
            self.dispatchFunction(action)
        }
    }

    public func dispatchAndWait(_ action: Action) {
        queue.writeAndWait {
            self.dispatchFunction(action)
        }
    }

    private func defaultDispatch(from action: Action) {
        queue.writeAndWait {
            self.currentState = self.reducer(action, self.currentState)
            self.observer.update(self.currentState)
        }
    }

    @discardableResult
    public func subscribe(on queue: DispatchQueue? = nil, includingCurrentState: Bool = true, observer: @escaping (State) -> Void) -> Disposable {
        let observer = Observer(queue: queue, update: observer)
        if includingCurrentState {
            observer.update(state)
        }
        return observable.subscribe(observer: observer)
    }

    public func stateObservable() -> Observable<State> {
        return observable
    }

    public func stateProducer() -> ObservableProducer<State> {
        return ObservableProducer { observer, disposables in
            disposables += self.subscribe(includingCurrentState: true, observer: observer.update)
        }
    }
}

extension Store where State: Equatable {
    @discardableResult
    public func subscribeUnique(on queue: DispatchQueue? = nil, includingCurrentState: Bool = true, observer: @escaping (State) -> Void) -> Disposable {
        if includingCurrentState {
            return stateProducer().skipRepeats().start(on: queue, observer: observer)
        } else {
            return stateObservable().skipRepeats().subscribe(on: queue, observer: observer)
        }
    }
}
