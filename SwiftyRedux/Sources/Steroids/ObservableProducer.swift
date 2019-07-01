import Dispatch

/// An ObservableProducer creates Observables that can produce values of type `Value`.
///
/// Observable producers do not do anything by themselves - work begins only when an observable is produced.
/// They can be used to represent operations or tasks, like network requests,
/// where each invocation of `start()` will create a new underlying operation.
/// This ensures that consumers will receive the results, versus a plain Observable,
/// where the results might be sent before any observers are attached.
///
/// Inspired by [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift).
/// [SignalProducer](https://github.com/ReactiveCocoa/ReactiveSwift/blob/master/Documentation/APIContracts.md#the-signalproducer-contract)
public final class ObservableProducer<Value> {
    private let startHandler: (Observer<Value>, CompositeDisposable) -> Void

    /// Initializes an `ObservableProducer` which invokes the supplied starting side
    /// effect once upon the creation of every produced `Observable`, or in other
    /// words, for every invocation of `startWithObservable()`, `start()` and their convenience shorthands.
    ///
    /// The supplied starting side effect would be given:
    /// 1. an input `Observer` to emit values to the produced `Observable`;
    /// 2. a `CompositeDisposable` to bind resources to the lifetime of the produced `Observable`.
    ///
    /// - Parameter startHandler: The starting side effect.
    public init(_ startHandler: @escaping (Observer<Value>, CompositeDisposable) -> Void) {
        self.startHandler = startHandler
    }

    /// Initializes a producer for an observable that immediately sends one value and nothing more.
    ///
    /// This initializer differs from `init(value:)` in that its sole `value` is constructed lazily
    /// by invoking the supplied `action` when the `ObservableProducer` is started.
    ///
    /// - Parameter action: An action that yields a value to be sent by the `Observable`.
    public convenience init(_ action: @escaping () -> Value) {
        self.init { observer, disposables in
            observer.update(action())
        }
    }

    /// Initializes a producer for an `Observable` that will immediately send one value and nothing more.
    ///
    /// - Parameter value: A value that should be sent by the `Observable`.
    public convenience init(_ value: Value) {
        self.init { observer, disposables in
            observer.update(value)
        }
    }

    /// Creates an `Observable` from `self`, and observe the `Observable` for all values being emitted.
    ///
    /// - Parameters:
    ///     - observingQueue: A queue on which to asynchronously receive updates. Defaults to `nil`.
    ///     - observer: A closure to be invoked with values from the produced `Observable`.
    /// - Returns: A disposable to interrupt the produced `Observable`.
    @discardableResult
    public func start(on observingQueue: DispatchQueue? = nil, observer: @escaping (Value) -> Void) -> Disposable {
        var disposable: Disposable!
        startWithObservable { observable, innerDisposables in
            innerDisposables += observable.subscribe(on: observingQueue, observer: observer)
            disposable = Disposable(action: innerDisposables.dispose)
        }
        return disposable
    }

    /// Creates an `Observable` from `self`, pass it into the given closure, and start the
    /// associated work on the produced `Observable` as the closure returns.
    ///
    /// - Parameter setup: A closure to be invoked before the work associated with the produced `Observable` commences.
    ///     Both the produced `Observable` and an interrupt handle of the observable would be passed to the closure.
    public func startWithObservable(_ setup: (Observable<Value>, CompositeDisposable) -> Void) {
        let disposables = CompositeDisposable()
        let (observable, observer) = Observable<Value>.pipe(disposable: Disposable(action: disposables.dispose))
        setup(observable, disposables)
        startHandler(observer, disposables)
    }

    /// Lifts an unary observable operator to operate upon observable producer instead.
    ///
    /// In other words, this will create a new `ObservableProducer` which will apply the given `Observable` operator
    /// to *every* created `Observable`, just as if the operator had been applied to each `Observable` yielded from `start()`.
    ///
    /// - Parameter transform: An unary operator to lift.
    /// - Returns: An observable producer that applies observable's operator to every created observable.
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

    /// Maps each value in the producer to a new value.
    ///
    /// - Parameter transform: A closure that accepts a value and returns a different value.
    /// - Returns: An observable producer that, when started, will send a mapped value of `self.`
    public func map<T>(_ transform: @escaping (Value) -> T) -> ObservableProducer<T> {
        return lift { $0.map(transform) }
    }

    /// Preserves only values which pass the given closure.
    ///
    /// - Parameter predicate: A closure to determine whether a value from `self` should be included in the produced `Observable`.
    /// - Returns: A producer that, when started, forwards the values passing the given closure.
    public func filter(_ predicate: @escaping (Value) -> Bool) -> ObservableProducer<Value> {
        return lift { $0.filter(predicate) }
    }

    /// Applies `transform` to values from the producer and forwards values with non `nil` results unwrapped.
    ///
    /// - Parameter transform: A closure that accepts a value and returns a new optional value.
    /// - Returns: A producer that will send new values, that are non `nil` after the transformation.
    public func filterMap<T>(_ transform: @escaping (Value) -> T?) -> ObservableProducer<T> {
        return lift { $0.filterMap(transform) }
    }

    /// Forwards only values from `self` that are not considered equivalent to its immediately preceding value.
    ///
    /// - Parameter isEquivalent: A closure to determine whether two values are equivalent.
    /// - Returns: A producer which conditionally forwards values from `self`
    ///
    /// - Note: The first value is always forwarded.
    public func skipRepeats(_ isEquivalent: @escaping (Value, Value) -> Bool) -> ObservableProducer<Value> {
        return lift { $0.skipRepeats(isEquivalent) }
    }

    /// Skips the first `count` values, then forward everything afterward.
    ///
    /// - Parameter count: A number of values to skip.
    /// - Returns:  A producer that, when started, will skip the first `count` values, then forward everything afterward.
    public func skip(first count: Int) -> ObservableProducer<Value> {
        return lift { $0.skip(first: count) }
    }

    /// Does not forward any value from `self` until `predicate` returns `false`,
    /// at which point the returned observable starts to forward values from `self`, including the one leading to the toggling.
    ///
    /// - Parameter predicate: A closure to determine whether the skipping should continue.
    /// - Returns: A producer which conditionally forwards values from `self`.
    public func skip(while predicate: @escaping (Value) -> Bool) -> ObservableProducer<Value> {
        return lift { $0.skip(while: predicate) }
    }

    /// Yields the first `count` values from the input producer.
    ///
    /// - Parameter count: A number of values to take from the observable.
    /// - Returns: A producer that, when started, will yield the first `count` values from `self`.
    ///
    /// - precondition: `count` must be non-negative number.
    public func take(first count: Int) -> ObservableProducer<Value> {
        return lift { $0.take(first: count) }
    }

    /// Forwards any values from `self` until `predicate` returns `false`, at which point the produced `Observable` would be disposed.
    ///
    /// - Parameter predicate: A closure to determine whether the forwarding of values should continue.
    /// - Returns: A producer which conditionally forwards values from `self`.
    public func take(while predicate: @escaping (Value) -> Bool) -> ObservableProducer<Value> {
        return lift { $0.take(while: predicate) }
    }

    /// Forwards events from `self` with history:
    /// values of the returned producer are tuples whose first member is the previous value
    /// and whose second member is the current value.
    /// `initial` is supplied as the first member when `self` sends its first value.
    /// If `initial` is `nil` the produced `Observable` would not emit any tuple until it has received at least two values.
    ///
    /// - Parameter initial: A value that will be combined with the first value sent by `self`.
    /// - Returns: A producer that sends tuples that contain previous and current sent values of `self`.
    public func combinePrevious(initial: Value? = nil) -> ObservableProducer<(Value, Value)> {
        return lift { $0.combinePrevious(initial: initial) }
    }
}

extension ObservableProducer where Value: Equatable {

    /// Forwards only values from `self` that are not equal to its immediately preceding value.
    ///
    /// - Returns: A producer which conditionally forwards values from `self`.
    ///
    /// - Note: The first value is always forwarded.
    public func skipRepeats() -> ObservableProducer<Value> {
        return skipRepeats(==)
    }
}

extension ObservableProducer {

    /// Maps each value in the producer to a new value by applying a key path.
    ///
    /// - Parameter keyPath: A key path relative to the producer's `Value` type.
    /// - Returns: A producer that will send new values.
    public func map<T>(_ keyPath: KeyPath<Value, T>) -> ObservableProducer<T> {
        return map { $0[keyPath: keyPath] }
    }

    /// Preserves only values by applying a key path whose value is `true`.
    ///
    /// - Parameter keyPath: A key path relative to the observable's `Value` type.
    /// - Returns: A producer that, when started, forwards the values passing the given closure.
    public func filter(_ keyPath: KeyPath<Value, Bool>) -> ObservableProducer<Value> {
        return filter { $0[keyPath: keyPath] }
    }
}
