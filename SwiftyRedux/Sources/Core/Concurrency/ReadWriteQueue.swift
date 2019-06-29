import Dispatch

// Queue that is targeted to solve reader-writer problem.
// Any amount of readers can access data at a time, but only one writer is allowed at a time.
// You read concurrently and synchronously for caller with `read` method.
// You write serially both asynchronously and synchronously with `write` and `writeAndWait` methods respectively.
//
// Note:
//  It's fine to have async write, and sync reads, because write blocks queue and reads are executed synchronously,
//  so if we want ro read after writing, we'll still be waiting (reads are sync) for write to finish and allow reads to execute.
//
// It's also safe to call `read` inside `write` and `write` inside `write`, etc.
// If you're trying to execute task while being already on this queue, it will safely execute this task without deadlocks.

internal final class ReadWriteQueue {
    private let specificKey = DispatchSpecificKey<String>()
    private let queue: DispatchQueue

    private var isAlreadyInQueue: Bool {
        return DispatchQueue.getSpecific(key: specificKey) == queue.label
    }

    internal init(label: String = "swifty-redux.read-write.queue") {
        queue = DispatchQueue(label: label, attributes: .concurrent)
        queue.setSpecific(key: specificKey, value: label)
    }

    deinit {
        queue.setSpecific(key: specificKey, value: nil)
    }

    internal func write(_ work: @escaping () -> Void) {
        if isAlreadyInQueue {
            work()
        } else {
            queue.async(flags: .barrier, execute: work)
        }
    }

    internal func writeAndWait(_ work: @escaping () -> Void) {
        if isAlreadyInQueue {
            work()
        } else {
            queue.sync(flags: .barrier, execute: work)
        }
    }

    internal func read<T>(_  work: () throws -> T) rethrows -> T {
        if isAlreadyInQueue {
            return try work()
        } else {
            return try queue.sync(execute: work)
        }
    }
}
