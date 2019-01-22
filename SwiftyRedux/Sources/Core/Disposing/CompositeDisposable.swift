import Dispatch

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
