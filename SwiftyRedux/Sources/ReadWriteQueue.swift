//
//  ReadWriteQueue.swift
//  SwiftyRedux
//
//  Created by Alexander Voronov on 12/16/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

import Dispatch

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
