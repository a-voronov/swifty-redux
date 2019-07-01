import ReactiveSwift

public extension Signal where Value == Action, Error == Never {
    func ofType<T: Action>(_ type: T.Type) -> Signal<T, Never> {
        return filterMap { value in
            value as? T
        }
    }
}

public extension Observable {

    /// - Returns: A ReactiveSwift.Signal which never fails that sends values of `self`.
    func toSignal() -> Signal<Value, Never> {
        return Signal { observer, lifetime in
            let disposable = self.subscribe(observer: observer.send)
            lifetime.observeEnded(disposable.dispose)
        }
    }
}

public extension Signal where Error == Never {

    /// - Returns: An observable that sends values of `self`.
    func toObservable() -> Observable<Value> {
        return Observable { update in
            self.observeValues(update).map(Disposable.init)
        }
    }
}

public extension ObservableProducer {

    /// - Returns: A ReactiveSwift.SignalProducer which never fails that, when started, will send values of `self.`
    func toSignalProducer() -> SignalProducer<Value, Never> {
        return SignalProducer { observer, lifetime in
            let disposable = self.start(observer: observer.send)
            lifetime.observeEnded(disposable.dispose)
        }
    }
}

public extension SignalProducer where Error == Never {

    /// - Returns: An ObservableProducer that, when started, will send values of `self.`
    func toObservableProducer() -> ObservableProducer<Value> {
        return ObservableProducer { observer, disposables in
            disposables += Disposable(disposable: self.startWithValues(observer.update))
        }
    }
}

public extension Disposable {

    /// Initializes a Disposable with ReactiveSwift.Disposable, that will be disposed when passed `disposable` is.
    /// If `disposable` is already disposed, it will be disposed as well.
    ///
    /// - Parameter disposable: ReactiveSwift.Disposable to hook up to.
    convenience init(disposable: ReactiveSwift.Disposable) {
        self.init(action: disposable.dispose)
        if disposable.isDisposed {
            dispose()
        }
    }
}
