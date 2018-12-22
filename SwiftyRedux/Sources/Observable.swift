//
//  Observable.swift
//  SwiftyRedux
//
//  Created by Alexander Voronov on 12/16/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

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
    private let queue: DispatchQueue
    private let disposeBag = DisposeBag()
    private var observers: Set<Observer<Value>> = []

    public init(id: String? = nil, observable: @escaping (@escaping (Value) -> Void) -> Disposable) {
        self.id = id ?? "redux.observable"
        self.queue = DispatchQueue(label: "\(self.id).queue")
        self.disposeBag += observable { value in
            self.queue.sync {
                self.observers.forEach { observer in observer.update(value) }
            }
        }
    }

    public convenience init(id: String? = nil, observable: Observable<Value>) {
        self.init(id: id, observable: { observable.subscribe(observer: $0) })
    }

    @discardableResult
    public func subscribe(on observingQueue: DispatchQueue? = nil, observer: @escaping (Value) -> Void) -> Disposable {
        let observer = Observer(queue: observingQueue, update: observer)
        _ = queue.sync {
            self.observers.insert(observer)
        }
        return disposeBag += ActionDisposable(id: "\(id).disposable") { [weak self, weak observer] in
            guard let strongSelf = self, let observer = observer else { return }
            _ = strongSelf.queue.sync {
                strongSelf.observers.remove(observer)
            }
        }
    }

    deinit {
        observers.removeAll()
    }
}

extension Observable {
    public func map<T>(_ transform: @escaping (Value) -> T) -> Observable<T> {
        return Observable<T>(id: "\(id)-map") { [weak self] action in
            guard let strongSelf = self else { return NopDisposable() }

            return strongSelf.subscribe { value in
                action(transform(value))
            }
        }
    }

    public func map<T>(_ keyPath: KeyPath<Value, T>) -> Observable<T> {
        return map { $0[keyPath: keyPath] }
    }

    public func filter(_ predicate: @escaping (Value) -> Bool) -> Observable<Value> {
        return Observable(id: "\(id)-filter") { [weak self] action in
            guard let strongSelf = self else { return NopDisposable() }

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
        return Observable<T>(id: "\(id)-filterMap") { [weak self] action in
            guard let strongSelf = self else { return NopDisposable() }

            return strongSelf.subscribe { value in
                transform(value).map(action)
            }
        }
    }

    public func skipRepeats(_ isEquivalent: @escaping (Value, Value) -> Bool) -> Observable<Value> {
        return Observable(id: "\(id)-skipRepeats") { [weak self] action in
            guard let strongSelf = self else { return NopDisposable() }

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
            guard let strongSelf = self else { return NopDisposable() }

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
            guard let strongSelf = self else { return NopDisposable() }

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
            guard let strongSelf = self else { return NopDisposable() }

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
            guard let strongSelf = self else { return NopDisposable() }

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
            guard let strongSelf = self else { return NopDisposable() }

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
    internal static func pipe<V>(id: String? = nil, queue: DispatchQueue? = nil, disposable: Disposable? = nil) -> (Observable<V>, Observer<V>) {
        var observer: Observer<V>!
        let observable = Observable<V>(id: id) { action -> Disposable in
            observer = Observer(queue: queue, update: action)
            return ActionDisposable(id: id.map { "\($0).disposable" }) {
                disposable?.dispose()
            }
        }
        return (observable, observer)
    }

    public static func pipe<V>(id: String? = nil, queue: DispatchQueue? = nil, disposable: Disposable? = nil) -> (Observable<V>, (V) -> Void) {
        let (observable, observer): (Observable<V>, Observer<V>) = Observable<V>.pipe(
            id: id,
            queue: queue,
            disposable: disposable
        )
        return (observable, observer.update)
    }
}
