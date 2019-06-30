import Dispatch

/// Queue whose purpose is to solve [Readers-writers problem](https://en.wikipedia.org/wiki/Readers–writers_problem).
///
/// Any amount of readers can access data at a time, but only one writer is allowed at a time:
/// * You read concurrently and synchronously for caller with `read` method.
/// * You write serially both asynchronously and synchronously with `write` and `writeAndWait` methods respectively.
///
/// It's fine to have async write operations, and sync read operations. Write ops block queue and read ops are executed synchronously,
/// so if we want ro read after writing, we'll still be waiting (reads are sync) for write ops to finish and allow read ops to execute.
///
/// - Note: It's safe to call `read` inside `write` and `write` inside `write`, etc.
///     If you're trying to execute task while being already on this queue, it will safely execute this task without deadlocks.
internal final class ReadWriteQueue {

    /// Unique key to identify internal queue among others.
    private let specificKey = DispatchSpecificKey<String>()

    /// Internal concurrent queue.
    private let queue: DispatchQueue

    /// Computed flag that tells whether we're already executing work on internal queue.
    private var isAlreadyInQueue: Bool {
        return DispatchQueue.getSpecific(key: specificKey) == queue.label
    }

    /// Initializes read-write queue with specified label.
    ///
    /// - Parameter label: Label to identify queue.
    internal init(label: String = "swifty-redux.read-write.queue") {
        queue = DispatchQueue(label: label, attributes: .concurrent)
        queue.setSpecific(key: specificKey, value: label)
    }

    deinit {
        queue.setSpecific(key: specificKey, value: nil)
    }

    /// Performs 'write' operation asynchronously
    /// by blocking the queue so that no other operations can be executed concurrently until it finishes.
    ///
    /// Basically - any async work, that doesn't require waiting for its completion or returning any result.
    /// If we're already working on this queue, `work` won't be enqued in the end of the queue but will be executed immediately.
    ///
    /// - Parameter work: Work to be executed.
    internal func write(_ work: @escaping () -> Void) {
        if isAlreadyInQueue {
            work()
        } else {
            queue.async(flags: .barrier, execute: work)
        }
    }

    /// Performs 'write' operation synchronously
    /// by blocking the queue so that no other operations can be executed concurrently until it finishes.
    ///
    /// Caller will wait until work is completed.
    /// If we're already working on this queue, there won't be any deadlocks and `work` will be executed immediately on this queue.
    ///
    /// - Parameter work: Work to be executed.
    internal func writeAndWait(_ work: @escaping () -> Void) {
        if isAlreadyInQueue {
            work()
        } else {
            queue.sync(flags: .barrier, execute: work)
        }
    }

    /// Performs 'read' operation synchronously by not blocking the queue so that many 'read' operations can be executed concurrently.
    ///
    /// Caller will wait until work is completed.
    /// If we're already working on this queue, there won't be any deadlocks and `work` will be executed immediately on this queue.
    ///
    /// - Parameter work: Work that returns value after it's executed.
    /// - Returns: Result of `work`.
    internal func read<T>(_  work: () throws -> T) rethrows -> T {
        if isAlreadyInQueue {
            return try work()
        } else {
            return try queue.sync(execute: work)
        }
    }
}
