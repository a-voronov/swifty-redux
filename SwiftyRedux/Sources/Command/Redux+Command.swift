/// Redux components extensions to receive Command instead of plain function for easier debugging.

// MARK: - Store

extension Store {
    @discardableResult
    public func subscribe(on queue: DispatchQueue? = nil, _ command: Command<State>) -> Disposable {
        return subscribe(on: queue, observer: command.execute)
    }
}

extension Store where State: Equatable {
    @discardableResult
    public func subscribe(on queue: DispatchQueue? = nil, skipRepeats: Bool = false, _ command: Command<State>) -> Disposable {
        return subscribe(on: queue, skipRepeats: skipRepeats, observer: command.execute)
    }
}

// MARK: - Observable

extension Observable {
    @discardableResult
    public func subscribe(on observingQueue: DispatchQueue? = nil, _ command: Command<Value>) -> Disposable {
        return subscribe(on: observingQueue, observer: command.execute)
    }
}

// MARK: - Observer

extension Observer {
    public convenience init(queue: DispatchQueue? = nil, _ command: Command<Value>) {
        self.init(queue: queue, update: command.execute)
    }
}

// MARK: - Disposable

extension Disposable {
    public convenience init(id: String? = nil, _ command: Command<Void>) {
        self.init(id: id, action: { command.execute() })
    }

    public convenience init(id: String? = nil, _ command: Command<Disposable?>) {
        self.init(id: id, action: command.execute)
    }
}
