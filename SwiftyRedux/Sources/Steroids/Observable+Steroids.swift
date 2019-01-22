extension Observable {
    public func map<T>(_ transform: @escaping (Value) -> T) -> Observable<T> {
        return Observable<T> { action in
            return self.subscribe { value in
                action(transform(value))
            }
        }
    }

    public func filter(_ predicate: @escaping (Value) -> Bool) -> Observable<Value> {
        return Observable { action in
            return self.subscribe { value in
                if predicate(value) {
                    action(value)
                }
            }
        }
    }

    public func filterMap<T>(_ transform: @escaping (Value) -> T?) -> Observable<T> {
        return Observable<T> { action in
            return self.subscribe { value in
                transform(value).map(action)
            }
        }
    }

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
