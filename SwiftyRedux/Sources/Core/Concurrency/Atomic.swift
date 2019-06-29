import Dispatch

/// Original: https://www.objc.io/blog/2018/12/18/atomic-variables/ but this one is analogous to r+w queue
/// Atomic value with concurrent access for reading value, and serial - for writing, both are executed synchronously

internal final class Atomic<T> {
    private var _value: T
    private let queue: DispatchQueue

    internal var value: T {
        return queue.sync { _value }
    }

    internal init(id: String = "swifty-redux.atomic", value: T) {
        _value = value
        queue = DispatchQueue(label: id + ".queue", attributes: .concurrent)
    }

    internal func mutate(_ transform: (inout T) -> Void) {
        queue.sync(flags: .barrier) {
            transform(&self._value)
        }
    }
}
