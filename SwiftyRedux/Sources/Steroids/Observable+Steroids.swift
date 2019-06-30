/// Observable extensions for value transformations.

extension Observable {

    /// Maps each value in the observable to a new value.
    ///
    /// - Parameter transform: A closure that accepts a value and returns a new value.
    /// - Returns: An observable that will send new values.
    public func map<T>(_ transform: @escaping (Value) -> T) -> Observable<T> {
        return Observable<T> { action in
            return self.subscribe { value in
                action(transform(value))
            }
        }
    }

    /// Preserves only values which pass the given closure.
    ///
    /// - Parameter predicate: A closure to determine whether a value from `self` should be included in the returned observable.
    /// - Returns: An observable that forwards the values passing the given closure.
    public func filter(_ predicate: @escaping (Value) -> Bool) -> Observable<Value> {
        return Observable { action in
            return self.subscribe { value in
                if predicate(value) {
                    action(value)
                }
            }
        }
    }

    /// Applies `transform` to values from observable and forwards values with non `nil` results unwrapped.
    ///
    /// - Parameter transform: A closure that accepts a value and returns a new optional value.
    /// - Returns: An observable that will send new values, that are non `nil` after the transformation.
    public func filterMap<T>(_ transform: @escaping (Value) -> T?) -> Observable<T> {
        return Observable<T> { action in
            return self.subscribe { value in
                transform(value).map(action)
            }
        }
    }

    /// Forwards only values that are not considered equivalent to its immediately preceding value.
    ///
    /// - Parameter isEquivalent: A closure to determine whether two values (previous and current) are equivalent.
    /// - Returns: An observable which conditionally forwards values from `self`.
    ///
    /// - Note: The first value is always forwarded.
    public func skipRepeats(_ isEquivalent: @escaping (Value, Value) -> Bool) -> Observable<Value> {
        return Observable { action in
            var previous: Value?
            return self.subscribe { value in
                if let previous = previous, isEquivalent(previous, value) {
                    return
                }
                previous = value
                action(value)
            }
        }
    }

    /// Skips first `count` number of values then act as usual.
    ///
    /// - Parameter count: A number of values to skip.
    /// - Returns: An observable that will skip the first `count` values, then forward everything afterward.
    ///
    /// - Precondition: `count` must be non-negative number.
    public func skip(first count: Int) -> Observable<Value> {
        precondition(count > 0)

        return Observable { action in
            var skipped = 0
            return self.subscribe { value in
                if skipped < count {
                    skipped += 1
                } else {
                    action(value)
                }
            }
        }
    }

    /// Does not forward any value from `self` until `predicate` returns `false`,
    /// at which point the returned observable starts to forward values from `self`, including the one leading to the toggling.
    ///
    /// - Parameter predicate: A closure to determine whether the skipping should continue.
    /// - Returns: An observable which conditionally forwards values from `self`.
    public func skip(while predicate: @escaping (Value) -> Bool) -> Observable<Value> {
        return Observable { action in
            var isSkipping = true
            return self.subscribe { value in
                isSkipping = isSkipping && predicate(value)
                if !isSkipping {
                    action(value)
                }
            }
        }
    }

    /// Takes up to `n` values from the observable and then dispose.
    ///
    /// - Parameter count: A number of values to take from the observable.
    /// - Returns: An observable that will yield the first `count` values from `self`
    ///
    /// - Precondition: `count` must be non-negative number.
    public func take(first count: Int) -> Observable<Value> {
        precondition(count > 0)

        return Observable { action in
            var taken = 0
            var disposable: Disposable!
            disposable = self.subscribe { value in
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

    /// Forwards any values from `self` until `predicate` returns `false`, at which point the returned observable would be disposed.
    ///
    /// - Parameter predicate: A closure to determine whether the forwarding of values should continue.
    /// - Returns: An observable which conditionally forwards values from `self`.
    public func take(while predicate: @escaping (Value) -> Bool) -> Observable<Value> {
        return Observable { action in
            var disposable: Disposable!
            disposable = self.subscribe { value in
                if predicate(value) {
                    action(value)
                } else {
                    disposable.dispose()
                }
            }
            return disposable
        }
    }

    /// Forwards value from `self` with history:
    /// values of the returned observable are tuples whose first member is the previous value
    /// and whose second member is the current value.
    /// `initial` is supplied as the first member when `self` sends its first value.
    /// If `initial` is `nil` the returned observable would not emit any tuple until it has received at least two values.
    ///
    /// - Parameter initial: A value that will be combined with the first value sent by `self`. Defaults to nil.
    /// - Returns: An observable that sends tuples that contain previous and current sent values of `self`.
    public func combinePrevious(initial: Value? = nil) -> Observable<(Value, Value)> {
        return Observable<(Value, Value)> { action in
            var previous = initial
            return self.subscribe { value in
                if let previous = previous {
                    action((previous, value))
                }
                previous = value
            }
        }
    }
}

extension Observable where Value: Equatable {

    /// Forwards only values from `self` that are not equal to its immediately preceding value.
    ///
    /// - Returns: An observable which conditionally forwards values from `self`.
    ///
    /// - Note: The first value is always forwarded.
    public func skipRepeats() -> Observable<Value> {
        return skipRepeats(==)
    }
}

extension Observable {

    /// Maps each value in the observable to a new value by applying a key path.
    ///
    /// - Parameter keyPath: A key path relative to the observable's `Value` type.
    /// - Returns: An observable that will send new values.
    public func map<T>(_ keyPath: KeyPath<Value, T>) -> Observable<T> {
        return map { $0[keyPath: keyPath] }
    }

    /// Preserves only values by applying a key path whose value is `true`.
    ///
    /// - Parameter keyPath: A key path relative to the observable's `Value` type.
    /// - Returns: An observable that forwards the values passing the given closure.
    public func filter(_ keyPath: KeyPath<Value, Bool>) -> Observable<Value> {
        return filter { $0[keyPath: keyPath] }
    }
}
