import Dispatch

/// Represents something that can be disposed, usually associated with freeing resources or canceling work.
///
/// Initialize it with action to execute once disposal is needed.
/// You can see whether action has been already executed with `isDisposed` flag. And it won't be executed twice.
public final class Disposable {
    private static func queue(id: String?) -> DispatchQueue {
        return DispatchQueue(label: (id ?? "swifty-redux.disposable") + ".queue", attributes: .concurrent)
    }

    /// Synchronization queue.
    private let queue: DispatchQueue

    /// Disposing action.
    private var action: (() -> Void)?

    private var _isDisposed: Bool = false

    /// Whether this disposable has been disposed already.
    ///
    /// - Remark: Thread-safe.
    public var isDisposed: Bool {
        return queue.sync { _isDisposed }
    }

    /// Initializes a disposable which runs the given `action` upon disposal.
    ///
    /// - Parameters:
    ///     - id: Unique identifier. Mostly used for internal queue label and debugging purposes. Defaults to `nil`.
    ///     - action: A closure to run when calling `dispose()`.
    public init(id: String? = nil, action: @escaping () -> Void) {
        self.queue = Disposable.queue(id: id)
        self.action = action
    }

    /// Disposes from any resources if not already disposed.
    ///
    /// Sets `isDisposed` to `true` and calls `action` afterwards. Calls `action` on a caller queue.
    /// Will not call `action` twice if it was already called and `isDisposed` is `true`.
    ///
    /// - Remark: Thread-safe.
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

    /// Creates no-op disposable with empty action which is already disposed.
    public static func nop() -> Disposable {
        return Disposable()
    }

    private init() {
        self.queue = DispatchQueue(label: "swifty-redux.nop-disposable.queue", attributes: .concurrent)
        self.action = nil
        self._isDisposed = true
    }
}

extension Disposable: Hashable {
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(ObjectIdentifier(self))
    }

    public static func == (lhs: Disposable, rhs: Disposable) -> Bool {
        return lhs === rhs
    }
}
