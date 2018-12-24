//
//  Lock.swift
//  SwiftyRedux
//
//  Created by Alexander Voronov on 12/24/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

/// unfair lock wrapper. works faster than gcd

final class Lock {
    private let _lock: os_unfair_lock_t

    init() {
        _lock = .allocate(capacity: 1)
        _lock.initialize(to: os_unfair_lock())
    }

    func lock() {
        os_unfair_lock_lock(_lock)
    }

    func unlock() {
        os_unfair_lock_unlock(_lock)
    }

    deinit {
        _lock.deinitialize(count: 1)
        _lock.deallocate()
    }
}
