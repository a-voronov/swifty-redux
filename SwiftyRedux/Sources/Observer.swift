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

final class Observer<Value> {
    let update: (Value) -> Void

    init(queue: DispatchQueue? = nil, update: @escaping (Value) -> Void) {
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
    var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    static func == (left: Observer, right: Observer) -> Bool {
        return left === right
    }
}
