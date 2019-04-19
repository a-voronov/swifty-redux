import Dispatch

/// Simple observer implementation.
/// Initialize it with update function and optional queue if you want to receive updates on it.

public final class Observer<Value> {
    public let update: (Value) -> Void

    public init(queue: DispatchQueue? = nil, update: @escaping (Value) -> Void) {
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
