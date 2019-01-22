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

    public static func == (lhs: Disposable, rhs: Disposable) -> Bool {
        return lhs === rhs
    }
}
