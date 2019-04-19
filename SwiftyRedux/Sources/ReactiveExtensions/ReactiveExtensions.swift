import ReactiveSwift
import Result

public extension Signal where Value == Action, Error == NoError {
    func ofType<T: Action>(_ type: T.Type) -> Signal<T, NoError> {
        return filterMap { value in
            value as? T
        }
    }
}

public extension Observable {
    func toSignal() -> Signal<Value, NoError> {
        return Signal { observer, lifetime in
            let disposable = self.subscribe(observer: observer.send)
            lifetime.observeEnded(disposable.dispose)
        }
    }
}

public extension Signal where Error == NoError {
    func toObservable() -> Observable<Value> {
        return Observable { update in
            self.observeValues(update).map(Disposable.init)
        }
    }
}

public extension ObservableProducer {
    func toSignalProducer() -> SignalProducer<Value, NoError> {
        return SignalProducer { observer, lifetime in
            let disposable = self.start(observer: observer.send)
            lifetime.observeEnded(disposable.dispose)
        }
    }
}

public extension SignalProducer where Error == NoError {
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
