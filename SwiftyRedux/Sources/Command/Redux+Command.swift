/// Redux components extensions to receive Command instead of plain function for easier debugging.

// MARK: - Store

extension Store {
    @discardableResult
    public func subscribe(on queue: DispatchQueue? = nil, observer: Command<State>) -> Disposable {
        return subscribe(on: queue, observer: observer.execute)
    }
}

extension Store where State: Equatable {
    @discardableResult
    public func subscribe(on queue: DispatchQueue? = nil, skipRepeats: Bool = false, observer: Command<State>) -> Disposable {
        return subscribe(on: queue, skipRepeats: skipRepeats, observer: observer.execute)
    }
}

// MARK: - Observable

extension Observable {
    @discardableResult
    public func subscribe(on observingQueue: DispatchQueue? = nil, observer: Command<Value>) -> Disposable {
        return subscribe(on: observingQueue, observer: observer.execute)
    }
}

// MARK: - Observer

extension Observer {
    public convenience init(queue: DispatchQueue? = nil, update: Command<Value>) {
        self.init(queue: queue, update: update.execute)
    }
}

// MARK: - Disposable

extension Disposable {
    public convenience init(id: String? = nil, action: Command<Void>) {
        self.init(id: id, action: { action.execute() })
    }

    public convenience init(id: String? = nil, action: Command<Disposable?>) {
        self.init(id: id, action: action.execute)
    }
}
