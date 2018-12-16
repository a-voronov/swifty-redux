//
//  ReadWriteQueue.swift
//  SwiftyRedux
//
//  Created by Alexander Voronov on 12/16/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

import Dispatch

/// Solving reader-writer problem here.
/// Wrapper over GCD concurrent queue, that performs concurrent reads and serial writes using barrier flag.
/// It can check whether work is already being executed on the same queue to not put it into then end of the queue, but to execute it here and now.
/// This option is disabled by default for performance reasons, but you can always choose to do so by passing `checkIfAlreadyInQueue` as true.
///
/// btw some good advices on concurrent programming in iOS can be found here: https://www.objc.io/issues/2-concurrency

final class ReadWriteQueue {
    private let specificKey = DispatchSpecificKey<String>()
    private let queue: DispatchQueue

    private var isAlreadyInQueue: Bool {
        return DispatchQueue.getSpecific(key: specificKey) == queue.label
    }

    init(label: String = "read-write.queue") {
        queue = DispatchQueue(label: label, attributes: .concurrent)
        queue.setSpecific(key: specificKey, value: label)
    }

    deinit {
        queue.setSpecific(key: specificKey, value: nil)
    }

    func write(checkIfAlreadyInQueue: Bool = false, work: @escaping () -> Void) {
        if checkIfAlreadyInQueue && isAlreadyInQueue {
            work()
        } else {
            queue.async(flags: .barrier, execute: work)
        }
    }

    func read<T>(checkIfAlreadyInQueue: Bool = false, work: () throws -> T) rethrows -> T {
        if checkIfAlreadyInQueue && isAlreadyInQueue {
            return try work()
        } else {
            return try queue.sync(execute: work)
        }
    }
}
