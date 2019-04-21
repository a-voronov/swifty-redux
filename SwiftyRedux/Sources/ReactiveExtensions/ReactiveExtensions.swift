import ReactiveSwift

public extension Signal where Value == Action, Error == Never {
    func ofType<T: Action>(_ type: T.Type) -> Signal<T, Never> {
        return filterMap { value in
            value as? T
        }
    }
}

public extension Observable {
    func toSignal() -> Signal<Value, Never> {
        return Signal { observer, lifetime in
            let disposable = self.subscribe(observer: observer.send)
            lifetime.observeEnded(disposable.dispose)
        }
    }
}

public extension Signal where Error == Never {
    func toObservable() -> Observable<Value> {
        return Observable { update in
            self.observeValues(update).map(Disposable.init)
        }
    }
}

public extension ObservableProducer {
    func toSignalProducer() -> SignalProducer<Value, Never> {
        return SignalProducer { observer, lifetime in
            let disposable = self.start(observer: observer.send)
            lifetime.observeEnded(disposable.dispose)
        }
    }
}

public extension SignalProducer where Error == Never {
    func toObservableProducer() -> ObservableProducer<Value> {
        return ObservableProducer { observer, disposables in
            disposables += Disposable(disposable: self.startWithValues(observer.update))
        }
    }
}

public extension Disposable {
    convenience init(disposable: ReactiveSwift.Disposable) {
        self.init(action: disposable.dispose)
        if disposable.isDisposed {
            dispose()
        }
    }
}
