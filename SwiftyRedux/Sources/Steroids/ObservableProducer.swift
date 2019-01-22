import Dispatch

public final class ObservableProducer<Value> {
    private let startHandler: (Observer<Value>, CompositeDisposable) -> Void

    public init(_ startHandler: @escaping (Observer<Value>, CompositeDisposable) -> Void) {
        self.startHandler = startHandler
    }

    public convenience init(_ action: @escaping () -> Value) {
        self.init { observer, disposables in
            observer.update(action())
        }
    }

    public convenience init(_ value: Value) {
        self.init { observer, disposables in
            observer.update(value)
        }
    }

    @discardableResult
    public func start(on observingQueue: DispatchQueue? = nil, observer: @escaping (Value) -> Void) -> Disposable {
        var disposable: Disposable!
        startWithObservable { observable, innerDisposables in
            innerDisposables += observable.subscribe(on: observingQueue, observer: observer)
            disposable = Disposable(action: innerDisposables.dispose)
        }
        return disposable
    }

    public func startWithObservable(_ setup: (Observable<Value>, CompositeDisposable) -> Void) {
        let disposables = CompositeDisposable()
        let (observable, observer) = Observable<Value>.pipe(disposable: Disposable(action: disposables.dispose))
        setup(observable, disposables)
        startHandler(observer, disposables)
    }

    public func lift<T>(_ transform: @escaping (Observable<Value>) -> Observable<T>) -> ObservableProducer<T> {
        return ObservableProducer<T> { observer, outerDisposables in
            self.startWithObservable { observable, innerDisposables in
                outerDisposables += innerDisposables
                transform(observable).subscribe(observer: observer.update)
            }
        }
    }
}

extension ObservableProducer {
    public func map<T>(_ transform: @escaping (Value) -> T) -> ObservableProducer<T> {
        return lift { $0.map(transform) }
    }

    public func filter(_ predicate: @escaping (Value) -> Bool) -> ObservableProducer<Value> {
        return lift { $0.filter(predicate) }
    }

    public func filterMap<T>(_ transform: @escaping (Value) -> T?) -> ObservableProducer<T> {
        return lift { $0.filterMap(transform) }
    }

    public func skipRepeats(_ isEquivalent: @escaping (Value, Value) -> Bool) -> ObservableProducer<Value> {
        return lift { $0.skipRepeats(isEquivalent) }
    }

    public func skip(first count: Int) -> ObservableProducer<Value> {
        return lift { $0.skip(first: count) }
    }

    public func skip(while predicate: @escaping (Value) -> Bool) -> ObservableProducer<Value> {
        return lift { $0.skip(while: predicate) }
    }

    public func take(first count: Int) -> ObservableProducer<Value> {
        return lift { $0.take(first: count) }
    }

    public func take(while predicate: @escaping (Value) -> Bool) -> ObservableProducer<Value> {
        return lift { $0.take(while: predicate) }
    }

    public func combinePrevious(initial: Value? = nil) -> ObservableProducer<(Value, Value)> {
        return lift { $0.combinePrevious(initial: initial) }
    }
}

extension ObservableProducer where Value: Equatable {
    public func skipRepeats() -> ObservableProducer<Value> {
        return skipRepeats(==)
    }
}

extension ObservableProducer {
    public func map<T>(_ keyPath: KeyPath<Value, T>) -> ObservableProducer<T> {
        return map { $0[keyPath: keyPath] }
    }

    public func filter(_ keyPath: KeyPath<Value, Bool>) -> ObservableProducer<Value> {
        return filter { $0[keyPath: keyPath] }
    }
}

