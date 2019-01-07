import Dispatch

/// Used to dispose from any resources when needed.
/// Initialize it with action to execute once disposal is needed.
/// Additionaly you can see whether action was already executed or not. And it won't be executed if it was already
/// Will serially execute action and toggle `isDisposed` flag.

public final class Disposable {
    private static func queue(id: String?) -> DispatchQueue {
        return DispatchQueue(label: (id ?? "redux.disposable") + ".queue", attributes: .concurrent)
    }

    private let queue: DispatchQueue
    private var action: (() -> Void)?

    private var _isDisposed: Bool = false
    public var isDisposed: Bool {
        return queue.sync { _isDisposed }
    }

    public init(id: String? = nil, action: @escaping () -> Void) {
        self.queue = Disposable.queue(id: id)
        self.action = action
    }

    public init(id: String? = nil, action: @escaping (Disposable?) -> Void) {
        self.queue = Disposable.queue(id: id)
        self.action = { [weak self] in
            action(self)
        }
    }

    public func dispose() {
        let shouldRunAction: Bool = queue.sync(flags: .barrier) {
            guard !self._isDisposed else { return false }
            self._isDisposed = true
            return true
        }
        if shouldRunAction {
            action?()
            action = nil
        }
    }

    public static func nop() -> Disposable {
        return Disposable()
    }

    private init() {
        self.queue = DispatchQueue(label: "redux.nop-disposable.queue", attributes: .concurrent)
        self.action = nil
        self._isDisposed = true
    }
}

extension Disposable: Hashable {
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    public static func == (left: Disposable, right: Disposable) -> Bool {
        return left === right
    }
}

public final class CompositeDisposable {
    private let queue: DispatchQueue
    private var disposables: Set<Disposable>?

    private var _isDisposed: Bool {
        return disposables == nil
    }
    public var isDisposed: Bool {
        return queue.sync { _isDisposed }
    }

    internal init(id: String? = nil, disposables: Set<Disposable>) {
        self.queue = DispatchQueue(label: (id ?? "redux.composite-disposable") + ".queue", attributes: .concurrent)
        self.disposables = disposables
    }

    public convenience init(id: String? = nil) {
        self.init(id: id, disposables: Set())
    }

    public convenience init(id: String? = nil, disposing disposables: Disposable...) {
        self.init(id: id, disposables: Set(disposables))
    }

    public convenience init(id: String? = nil, disposing disposables: [Disposable]) {
        self.init(id: id, disposables: Set(disposables))
    }

    public func add(_ disposable: Disposable) {
        _ = queue.sync(flags: .barrier) {
            guard !_isDisposed else {
                disposable.dispose()
                return
            }
            disposables?.insert(disposable)
        }
    }

    public func remove(_ disposable: Disposable) {
        _ = queue.sync(flags: .barrier) {
            disposables?.remove(disposable)
        }
    }

    public func add(_ disposables: [Disposable]) {
        _ = queue.sync(flags: .barrier) {
            guard !_isDisposed else {
                disposables.forEach { $0.dispose() }
                return
            }
            self.disposables?.formUnion(Set(disposables))
        }
    }

    public func dispose() {
        let currentDisposables: Set<Disposable>? = queue.sync(flags: .barrier) {
            let currentDisposables = disposables
            disposables?.removeAll(keepingCapacity: false)
            disposables = nil
            return currentDisposables
        }
        currentDisposables?.forEach { $0.dispose() }
    }
}

extension CompositeDisposable {
    @discardableResult
    public static func += (lhs: CompositeDisposable, rhs: Disposable) -> Disposable {
        lhs.add(rhs)
        return rhs
    }

    @discardableResult
    public static func += (lhs: CompositeDisposable, rhs: Disposable?) -> Disposable? {
        rhs.map(lhs.add)
        return rhs
    }

    @discardableResult
    public static func += (lhs: CompositeDisposable, rhs: @escaping () -> Void) -> Disposable {
        let disposable = Disposable(action: rhs)
        lhs.add(disposable)
        return disposable
    }
}
