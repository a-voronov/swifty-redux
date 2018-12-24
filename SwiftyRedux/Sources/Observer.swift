//
//  Observer.swift
//  SwiftyRedux
//
//  Created by Alexander Voronov on 12/16/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

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
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    public static func == (left: Observer, right: Observer) -> Bool {
        return left === right
    }
}
