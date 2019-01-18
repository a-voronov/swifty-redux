import Dispatch

/// Just an implementation of Observable.
/// You can initialize it with another observable as an instance of this class or as an anonymous function.
/// It has its own queue to manage observers list modifications and sending updates in a serial way.
/// You can apply any of available transforming or filtering functions to only receive updates you're interested in.
/// Once you're ready, call `subscribe` method to pass observer - you'll be returned `Disposable` to stop listening for updates.
///
/// There's also handy function `pipe` that gives you both:
/// - `observable` to listen to updates
/// - `observer` to send updates to, so that observable would get them and propagate to its observers.

public final class Observable<Value> {
    private let id: String
    private let disposables: CompositeDisposable
    private let observers: Atomic<Set<Observer<Value>>>

    public init(id: String? = nil, observable: @escaping (@escaping (Value) -> Void) -> Disposable?) {
        self.id = id ?? "redux.observable"
        self.observers = Atomic(id: self.id, value: Set())
        self.disposables = CompositeDisposable(id: "\(self.id).composite-disposable")
        self.disposables += observable { value in
            let currentObservers = self.observers.value
            currentObservers.forEach { observer in observer.update(value) }
        }
    }

    public convenience init(id: String? = nil, observable: Observable<Value>) {
        self.init(id: id, observable: { observable.subscribe(observer: $0) })
    }

    @discardableResult
    public func subscribe(on observingQueue: DispatchQueue? = nil, observer: @escaping (Value) -> Void) -> Disposable {
        let observer = Observer(queue: observingQueue, update: observer)
        observers.mutate { $0.insert(observer) }

        return disposables += Disposable(id: "\(id).disposable") { [weak self, weak observer] disposable in
            guard let strongSelf = self, let observer = observer else { return }
            strongSelf.observers.mutate { $0.remove(observer) }
            // kinda optimization not to store all the disposables (in case this Observable is intended for Store)
            disposable.map(strongSelf.disposables.remove)
        }
    }

    deinit {
        disposables.dispose()
        observers.mutate { $0.removeAll() }
    }
}

extension Observable {
    public func map<T>(_ transform: @escaping (Value) -> T) -> Observable<T> {
        return Observable<T>(id: "\(id)-map") { [weak self] action in
            guard let strongSelf = self else { return nil }

            return strongSelf.subscribe { value in
                action(transform(value))
            }
        }
    }

    public func filter(_ predicate: @escaping (Value) -> Bool) -> Observable<Value> {
        return Observable(id: "\(id)-filter") { [weak self] action in
            guard let strongSelf = self else { return nil }

            return strongSelf.subscribe { value in
                if predicate(value) {
                    action(value)
                }
            }
        }
    }

    public func filterMap<T>(_ transform: @escaping (Value) -> T?) -> Observable<T> {
        return Observable<T>(id: "\(id)-filterMap") { [weak self] action in
            guard let strongSelf = self else { return nil }

            return strongSelf.subscribe { value in
                transform(value).map(action)
            }
        }
    }

    public func skipRepeats(_ isEquivalent: @escaping (Value, Value) -> Bool) -> Observable<Value> {
        return Observable(id: "\(id)-skipRepeats") { [weak self] action in
            guard let strongSelf = self else { return nil }

            var previous: Value?
            return strongSelf.subscribe { value in
                if let previous = previous, isEquivalent(previous, value) {
                    return
                }
                previous = value
                action(value)
            }
        }
    }

    public func skip(first count: Int) -> Observable<Value> {
        precondition(count > 0)

        return Observable(id: "\(id)-skipFirst") { [weak self] action in
            guard let strongSelf = self else { return nil }

            var skipped = 0
            return strongSelf.subscribe { value in
                if skipped < count {
                    skipped += 1
                } else {
                    action(value)
                }
            }
        }
    }

    public func skip(while predicate: @escaping (Value) -> Bool) -> Observable<Value> {
        return Observable(id: "\(id)-skipWhile") { [weak self] action in
            guard let strongSelf = self else { return nil }

            var isSkipping = true
            return strongSelf.subscribe { value in
                isSkipping = isSkipping && predicate(value)
                if !isSkipping {
                    action(value)
                }
            }
        }
    }

    public func take(first count: Int) -> Observable<Value> {
        precondition(count > 0)

        return Observable(id: "\(id)-takeFirst") { [weak self] action in
            guard let strongSelf = self else { return nil }

            var taken = 0
            var disposable: Disposable!
            disposable = strongSelf.subscribe { value in
                if taken < count {
                    taken += 1
                    action(value)
                } else {
                    disposable.dispose()
                }
            }
            return disposable
        }
    }

    public func take(while predicate: @escaping (Value) -> Bool) -> Observable<Value> {
        return Observable(id: "\(id)-takeWhile") { [weak self] action in
            guard let strongSelf = self else { return nil }

            var disposable: Disposable!
            disposable = strongSelf.subscribe { value in
                if predicate(value) {
                    action(value)
                } else {
                    disposable.dispose()
                }
            }
            return disposable
        }
    }

    public func combinePrevious(initial: Value? = nil) -> Observable<(Value, Value)> {
        return Observable<(Value, Value)>(id: "\(id)-combinePrevious") { [weak self] action in
            guard let strongSelf = self else { return nil }

            var previous = initial
            return strongSelf.subscribe { value in
                if let previous = previous {
                    action((previous, value))
                }
                previous = value
            }
        }
    }
}

extension Observable where Value: Equatable {
    public func skipRepeats() -> Observable<Value> {
        return skipRepeats(==)
    }
}

extension Observable {
    public func map<T>(_ keyPath: KeyPath<Value, T>) -> Observable<T> {
        return map { $0[keyPath: keyPath] }
    }

    public func filter(_ keyPath: KeyPath<Value, Bool>) -> Observable<Value> {
        return filter { $0[keyPath: keyPath] }
    }
}

extension Observable {
    public static func pipe(id: String? = nil, queue: DispatchQueue? = nil, disposable: Disposable? = nil) -> (Observable, Observer<Value>) {
        var observer: Observer<Value>!
        let observable = Observable(id: id) { action in
            observer = Observer(queue: queue, update: action)
            return disposable
        }
        return (observable, observer)
    }
}
