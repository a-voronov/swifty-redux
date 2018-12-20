//
//  Store.swift
//  SwiftyRedux
//
//  Created by Alexander Voronov on 12/16/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

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
    private let middleware: Middleware<State>
    private let queue: DispatchQueue
    private let (observable, observer): (Observable<State>, Observer<State>)

    private var currentState: State
    public var state: State {
        return queue.sync { currentState }
    }

    public init(id: String = "redux.store", state: State, reducer: @escaping Reducer<State>, middleware: [Middleware<State>] = []) {
        self.queue = DispatchQueue(label: "\(id).queue", attributes: .concurrent)
        self.currentState = state
        self.reducer = reducer
        self.middleware = applyMiddleware(middleware)

        (observable, observer) = Observable<State>.pipe(id: "\(id).observable")
    }

    public func dispatch(_ action: Action) {
        let dispatchFunction = middleware(
            { self.state },
            { [weak self] in self?.dispatch($0) },
            { [weak self] action in self?.defaultDispatch(from: action) }
        )
        dispatchFunction(action)
    }

    private func defaultDispatch(from action: Action) {
        queue.async(flags: .barrier) {
            self.currentState = self.reducer(action, self.currentState)
            self.observer.update(self.currentState)
        }
    }

    @discardableResult
    public func subscribe(on queue: DispatchQueue? = nil, observer: @escaping (State) -> Void) -> Disposable {
        return observable.subscribe(on: queue, observer: observer)
    }

    public func observe() -> Observable<State> {
        return observable
    }
}

extension Store where State: Equatable {
    @discardableResult
    public func subscribe(on queue: DispatchQueue? = nil, skipRepeats: Bool = false, observer: @escaping (State) -> Void) -> Disposable {
        if skipRepeats {
            return observable.skipRepeats().subscribe(on: queue, observer: observer)
        }
        return observable.subscribe(on: queue, observer: observer)
    }
}
