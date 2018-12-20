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
    public static var defaultId: String {
        return "redux.observable"
    }

    private let id: String
    private let queue: ReadWriteQueue
    private var disposable: Disposable!
    private var observers: Set<Observer<Value>> = []

    internal init(id: String = defaultId, queue: ReadWriteQueue? = nil, observable: @escaping (@escaping (Value) -> Void) -> Disposable) {
        self.id = id
        self.queue = queue ?? ReadWriteQueue(label: "\(id).queue")
        self.disposable = observable { value in
            // we only need to check if we're already running on a queue if we didn't create that queue
            self.queue.write(checkIfAlreadyInQueue: queue != nil) {
                self.observers.forEach { observer in observer.update(value) }
            }
        }
    }

    internal convenience init(id: String = defaultId, queue: ReadWriteQueue? = nil, observable: Observable<Value>) {
        self.init(id: id, queue: queue, observable: { observable.subscribe(observer: $0) })
    }

    public convenience init(id: String = defaultId, observable: @escaping (@escaping (Value) -> Void) -> Disposable) {
        self.init(id: id, queue: nil, observable: observable)
    }

    public convenience init(id: String = defaultId, observable: Observable<Value>) {
        self.init(id: id, queue: nil, observable: observable)
    }

    public func subscribe(on observingQueue: DispatchQueue? = nil, observer: @escaping (Value) -> Void) -> Disposable {
        let observer = Observer(queue: observingQueue, update: observer)
        queue.write {
            self.observers.insert(observer)
        }
        #warning("🤔: add all disposables to dispose bag, so that all of them are disposed after bag is disposed")
        return DisposableAction(id: "\(id).disposable") { [weak self, weak observer] in
            guard let strongSelf = self, let observer = observer else { return }
            strongSelf.queue.write {
                strongSelf.observers.remove(observer)
            }
        }
    }

    deinit {
        disposable?.dispose()
        observers.removeAll()
    }
}

extension Observable {
    /// `bind` is mostly needed to pass queue internally,
    /// so that any transformations could be executed on a same queue by default -
    /// thus providing predictive behaviour in case of synchronous events

    public func bind<T>(id: String = defaultId, observable: @escaping (@escaping (T) -> Void) -> Disposable) -> Observable<T> {
        return Observable<T>(id: id, queue: queue, observable: observable)
    }

    public func bind<T>(id: String = defaultId, observable: Observable<T>) -> Observable<T> {
        return Observable<T>(id: id, queue: queue, observable: observable)
    }

    public func map<T>(_ transform: @escaping (Value) -> T) -> Observable<T> {
        return bind(id: "\(id)-map") { [weak self] action in
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
        return bind(id: "\(id)-filter") { [weak self] action in
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
        return bind(id: "\(id)-filterMap") { [weak self] action in
            guard let strongSelf = self else { return NopDisposable() }

            return strongSelf.subscribe { value in
                transform(value).map(action)
            }
        }
    }

    public func skipRepeats(_ isEquivalent: @escaping (Value, Value) -> Bool) -> Observable<Value> {
        return bind(id: "\(id)-skipRepeats") { [weak self] action in
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

        return bind(id: "\(id)-skipFirst") { [weak self] action in
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
        return bind(id: "\(id)-skipWhile") { [weak self] action in
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

        return bind(id: "\(id)-takeFirst") { [weak self] action in
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
        return bind(id: "\(id)-takeWhile") { [weak self] action in
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
        return bind(id: "\(id)-combinePrevious") { [weak self] action in
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
    internal static func pipe<V>(
        id: String = defaultId,
        observableQueue: ReadWriteQueue? = nil,
        observerQueue: DispatchQueue? = nil,
        disposable: Disposable? = nil
    ) -> (Observable<V>, Observer<V>) {
        var observer: Observer<V>!
        let observable = Observable<V>(id: id, queue: observableQueue) { action -> Disposable in
            observer = Observer(queue: observerQueue, update: action)
            return DisposableAction(id: "\(id).disposable") {
                disposable?.dispose()
            }
        }
        return (observable, observer)
    }

    public static func pipe<V>(id: String = defaultId, queue: DispatchQueue? = nil, disposable: Disposable? = nil) -> (Observable<V>, (V) -> Void) {
        let (observable, observer): (Observable<V>, Observer<V>) = Observable<V>.pipe(
            id: id,
            observerQueue: queue,
            disposable: disposable
        )
        return (observable, observer.update)
    }
}
