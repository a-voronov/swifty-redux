extension Store {

    /// Creates observable to receive state changing updates.
    /// Will send only further updates as they appear without current state at the moment of creating observer.
    /// Use it to declaratively transform state.
    ///
    /// Example:
    ///
    ///     store.stateObservable()
    ///         .map(\.networking)
    ///         .filter(\.isReachable)
    ///         .skipRepeats()
    ///         .subscribe { networkingState in
    ///             // ...
    ///         }
    ///
    /// - Returns: An observable that will send new store's state.
    public func stateObservable() -> Observable<State> {
        return Observable { action in
            return self.subscribe(includingCurrentState: false, observer: action)
        }
    }

    /// Creates observable producer to receive state changing updates once started.
    /// Will immediately send current state once started and then will send further updates as they appear.
    /// Use it to declaratively transform state.
    ///
    /// Example:
    ///
    ///     store.stateProducer()
    ///         .map(\.profiles)
    ///         .filterMap { profilesState in
    ///             profilesState[profileId]
    ///         }
    ///         .skipRepeats()
    ///         .start { profileById in
    ///             // ...
    ///         }
    ///
    /// - Returns: An observable producer that, when started, will send store's state`
    public func stateProducer() -> ObservableProducer<State> {
        return ObservableProducer { observer, disposables in
            disposables += self.subscribe(includingCurrentState: true, observer: observer.update)
        }
    }
}

extension Store where State: Equatable {

    /// Subscribes a unique state update observer.
    /// It will be called any time an action is dispatched, and some part of the state tree may potentially have changed,
    /// and new state doesn't equal to the previous one. Thus if no changes were made to the state, observer won't be called.
    /// You can stop listening to updates by calling `dispose()` on returned disposable.
    ///
    /// - Parameters:
    ///     - queue: A queue on which observer wants to receive updates. If `nil`, observer will be called on internal queue. Defaults to `nil`.
    ///     - includingCurrentState: If `true`, observer will immediately receive current state
    ///         (before creating and returning Disposable) and further updates as they appear.
    ///         If `false`, observer will only receive further updates as they appear. Defaults to `true`.
    ///     - observer: Observer callback that will receive new unique state after each update until it's manually disposed or store's dead.
    ///     - state: Current state right after it's changed and not equal to previous one.
    /// - Returns: Disposable to stop listening to updates.
    ///     Its `isDisposed` property will be `true` when store dies and cancels all subscriptions by itself.
    @discardableResult
    public func subscribeUnique(on queue: DispatchQueue? = nil, includingCurrentState: Bool = true, observer: @escaping (State) -> Void) -> Disposable {
        if includingCurrentState {
            return stateProducer().skipRepeats().start(on: queue, observer: observer)
        }
        return stateObservable().skipRepeats().subscribe(on: queue, observer: observer)
    }
}
