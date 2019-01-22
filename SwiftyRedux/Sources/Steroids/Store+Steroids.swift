extension Store {
    public func stateObservable() -> Observable<State> {
        return Observable { action in
            return self.subscribe(includingCurrentState: false, observer: action)
        }
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
        }
        return stateObservable().skipRepeats().subscribe(on: queue, observer: observer)
    }
}
