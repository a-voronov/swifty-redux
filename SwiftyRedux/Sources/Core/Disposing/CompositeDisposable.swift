import Dispatch

/// A disposable that will dispose of any number of other disposables.
public final class CompositeDisposable {

    /// Synchronization queue.
    private let queue: DispatchQueue

    /// Set of disposables. Duplicates will be ignored.
    private var disposables: Set<Disposable>?

    /// Treats disposables `nil` value as a sign of composite disposable being disposed.
    private var _isDisposed: Bool {
        return disposables == nil
    }

    /// Whether composite disposable has been disposed already.
    ///
    /// - Remark: Thread-safe.
    public var isDisposed: Bool {
        return queue.sync { _isDisposed }
    }

    /// Initializes a composite disposable containing the given set of disposables.
    ///
    /// - Parameters:
    ///     - id: Unique identifier. Mostly used for internal queue label and debugging purposes. Defaults to `nil`.
    ///     - disposables: A set of disposables to hook up with composite disposable.
    internal init(id: String? = nil, disposables: Set<Disposable>) {
        self.queue = DispatchQueue(label: (id ?? "swifty-redux.composite-disposable") + ".queue", attributes: .concurrent)
        self.disposables = disposables
    }

    /// Initializes an empty composite disposable
    ///
    /// - Parameters:
    ///     - id: Unique identifier. Mostly used for internal queue label and debugging purposes. Defaults to `nil`.
    public convenience init(id: String? = nil) {
        self.init(id: id, disposables: Set())
    }

    /// Initializes a composite disposable containing the given variadic parameter of disposables.
    ///
    /// - Parameters:
    ///     - id: Unique identifier. Mostly used for internal queue label and debugging purposes. Defaults to `nil`.
    ///     - disposables: A variadic parameter of disposables to hook up with composite disposable.
    public convenience init(id: String? = nil, disposing disposables: Disposable...) {
        self.init(id: id, disposables: Set(disposables))
    }

    /// Initializes a composite disposable containing the given array of disposables.
    ///
    /// - Parameters:
    ///     - id: Unique identifier. Mostly used for internal queue label and debugging purposes. Defaults to `nil`.
    ///     - disposables: An array of disposables to hook up with composite disposable.
    public convenience init(id: String? = nil, disposing disposables: [Disposable]) {
        self.init(id: id, disposables: Set(disposables))
    }

    /// Add the given disposable to the composite.
    ///
    /// If composite is already disposed, will dispose `disposible` synchronously on a caller queue.
    ///
    /// - Parameter disposable: A disposable.
    ///
    /// - Remark: Thread-safe
    public func add(_ disposable: Disposable) {
        let toDispose: Disposable? = queue.sync(flags: .barrier) {
            guard !_isDisposed else {
                return disposable
            }
            disposables?.insert(disposable)
            return nil
        }
        toDispose?.dispose()
    }

    /// Add the given disposables to the composite.
    ///
    /// If composite is already disposed, will dispose each one from `disposibles` synchronously on a caller queue.
    ///
    /// - Parameter disposables: An array of disposable.
    ///
    /// - Remark: Thread-safe
    public func add(_ disposables: [Disposable]) {
        let toDispose: [Disposable]? = queue.sync(flags: .barrier) {
            guard !_isDisposed else {
                return disposables
            }
            self.disposables?.formUnion(Set(disposables))
            return nil
        }
        toDispose?.forEach { $0.dispose() }
    }

    /// Removes given disposable from contained set if it's there. Does nothing otherwise.
    ///
    /// - Parameter disposable: Disposable to remove.
    public func remove(_ disposable: Disposable) {
        _ = queue.sync(flags: .barrier) {
            disposables?.remove(disposable)
        }
    }

    /// Disposes all contained disposables.
    ///
    /// Removes all contained disposables and disposes each of them synchronously on a caller queue.
    ///
    /// - Remark: Thread-safe
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
    /// Adds the right-hand-side composite disposable to the left-hand-side composite disposable
    /// by wrapping it into Disposable.
    ///
    /// - Parameters:
    ///     - lhs: Composite disposable to add to.
    ///     - rhs: Composite disposable to add.
    /// - Returns: Disposable that can be used to remove the disposable (that binds rhs) later.
    @discardableResult
    public static func += (lhs: CompositeDisposable, rhs: CompositeDisposable) -> Disposable {
        let disposable = Disposable(action: rhs.dispose)
        lhs.add(disposable)
        return disposable
    }

    /// Adds the right-hand-side disposable to the left-hand-side composite disposable.
    ///
    /// - Parameters:
    ///     - lhs: Composite disposable to add to.
    ///     - rhs: Disposable to add.
    /// - Returns: Disposable that can be used to remove the disposable later.
    @discardableResult
    public static func += (lhs: CompositeDisposable, rhs: Disposable) -> Disposable {
        lhs.add(rhs)
        return rhs
    }

    /// Adds the right-hand-side disposable if exists to the left-hand-side composite disposable.
    /// If right-hand-side disposable is `nil`, nothing happens and `nil` is returned.
    ///
    /// - Parameters:
    ///     - lhs: Composite disposable to add to.
    ///     - rhs: Disposable to add.
    /// - Returns: Disposable that can be used to remove the disposable later.
    @discardableResult
    public static func += (lhs: CompositeDisposable, rhs: Disposable?) -> Disposable? {
        rhs.map(lhs.add)
        return rhs
    }

    /// Adds the right-hand-side action to the left-hand-side composite disposable.
    ///
    /// - Parameters:
    ///     - lhs: Composite disposable to add to.
    ///     - rhs: A closure to be invoked when the composite is disposed of.
    /// - Returns: Disposable that can be used to remove the disposable later.
    @discardableResult
    public static func += (lhs: CompositeDisposable, rhs: @escaping () -> Void) -> Disposable {
        let disposable = Disposable(action: rhs)
        lhs.add(disposable)
        return disposable
    }
}
