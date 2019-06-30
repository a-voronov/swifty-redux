import Dispatch

/// An Observer is a simple wrapper around a function which can receive Values on a given queue.
public final class Observer<Value> {

    /// A handler to send values to the listener.
    public let update: (_ value: Value) -> Void

    /// Initializes observer with a `queue` to receive updates on, and `update` callback to receive values.
    ///
    /// - Parameters:
    ///     - queue: A queue on which to asynchronously receive updates.
    ///         If `nil`, updates will be received on a caller queue. Defaults to `nil`.
    ///     - update: Callback that will receive new values.
    ///     - value: New value.
    public init(queue: DispatchQueue? = nil, update: @escaping (_ value: Value) -> Void) {
        guard let queue = queue else {
            self.update = update
            return
        }
        self.update = { value in
            queue.async {
                update(value)
            }
        }
    }
}

extension Observer: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public static func == (lhs: Observer, rhs: Observer) -> Bool {
        return lhs === rhs
    }
}
