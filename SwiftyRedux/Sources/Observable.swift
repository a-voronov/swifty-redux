//
//  Observable.swift
//  SwiftyRedux
//
//  Created by Alexander Voronov on 12/16/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

//import Dispatch

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
    private let lock = Lock()
    private let disposables: CompositeDisposable
    private var observers = Set<Observer<Value>>()

    public init(observable: @escaping (@escaping (Value) -> Void) -> Disposable) {
        self.disposables = CompositeDisposable()
        self.disposables += observable { value in
            self.lock.lock()
            let currentObservers = self.observers
            self.lock.unlock()
            currentObservers.forEach { observer in observer.update(value) }
        }
    }

    public convenience init(observable: Observable<Value>) {
        self.init(observable: { observable.subscribe(observer: $0) })
    }

    @discardableResult
    public func subscribe(on observingQueue: DispatchQueue? = nil, observer: @escaping (Value) -> Void) -> Disposable {
        let observer = Observer(queue: observingQueue, update: observer)

        lock.lock()
        self.observers.insert(observer)
        lock.unlock()

        let disposable = Disposable { [weak self, weak observer] in
            guard let strongSelf = self, let observer = observer else { return }
            strongSelf.lock.lock(); defer { strongSelf.lock.unlock() }
            strongSelf.observers.remove(observer)
        }
        // small hack to remove disposable when it's disposed
        disposable.onDisposed = { [weak self, weak disposable] in
            if let disposable = disposable {
                self?.disposables.remove(disposable)
            }
        }
        return disposables += disposable
    }

    deinit {
        disposables.dispose()
        observers.removeAll()
    }
}

extension Observable {
    public func map<T>(_ transform: @escaping (Value) -> T) -> Observable<T> {
        return Observable<T> { [weak self] action in
            guard let strongSelf = self else { return .nop() }

            return strongSelf.subscribe { value in
                action(transform(value))
            }
        }
    }

    public func map<T>(_ keyPath: KeyPath<Value, T>) -> Observable<T> {
        return map { $0[keyPath: keyPath] }
    }

    public func filter(_ predicate: @escaping (Value) -> Bool) -> Observable<Value> {
        return Observable { [weak self] action in
            guard let strongSelf = self else { return .nop() }

            return strongSelf.subscribe { value in
                if predicate(value) {
                    action(value)
                }
            }
        }
    }

    public func filter(_ keyPath: KeyPath<Value, Bool>) -> Observable<Value> {
        return filter { $0[keyPath: keyPath] }
    }

    public func filterMap<T>(_ transform: @escaping (Value) -> T?) -> Observable<T> {
        return Observable<T> { [weak self] action in
            guard let strongSelf = self else { return .nop() }

            return strongSelf.subscribe { value in
                transform(value).map(action)
            }
        }
    }

    public func skipRepeats(_ isEquivalent: @escaping (Value, Value) -> Bool) -> Observable<Value> {
        return Observable { [weak self] action in
            guard let strongSelf = self else { return .nop() }

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

        return Observable { [weak self] action in
            guard let strongSelf = self else { return .nop() }

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
        return Observable { [weak self] action in
            guard let strongSelf = self else { return .nop() }

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

        return Observable { [weak self] action in
            guard let strongSelf = self else { return .nop() }

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
        return Observable { [weak self] action in
            guard let strongSelf = self else { return .nop() }

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
        return Observable<(Value, Value)> { [weak self] action in
            guard let strongSelf = self else { return .nop() }

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
    internal static func pipe<V>(queue: DispatchQueue? = nil, disposable: Disposable? = nil) -> (Observable<V>, Observer<V>) {
        var observer: Observer<V>!
        let observable = Observable<V> { action -> Disposable in
            observer = Observer(queue: queue, update: action)
            return disposable ?? .nop()
        }
        return (observable, observer)
    }

    public static func pipe<V>(queue: DispatchQueue? = nil, disposable: Disposable? = nil) -> (Observable<V>, (V) -> Void) {
        let (observable, observer): (Observable<V>, Observer<V>) = Observable<V>.pipe(queue: queue, disposable: disposable)
        return (observable, observer.update)
    }
}
