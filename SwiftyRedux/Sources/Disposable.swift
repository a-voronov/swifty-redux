//
//  Disposable.swift
//  SwiftyRedux
//
//  Created by Alexander Voronov on 12/16/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

public protocol Disposable {
    var isDisposed: Bool { get }

    func dispose()
}

final class DisposableAction: Disposable {
    private let queue: ReadWriteQueue
    private let action: () -> Void

    private var _isDisposed: Bool = false
    var isDisposed: Bool {
        return queue.read { _isDisposed }
    }

    init(id: String = "redux.disposable", action: @escaping () -> Void) {
        self.queue = ReadWriteQueue(label: "\(id).queue")
        self.action = action
    }

    func dispose() {
        queue.write {
            guard !self._isDisposed else { return }
            self.action()
            self._isDisposed = true
        }
    }
}

final class NopDisposable: Disposable {
    let isDisposed: Bool = true
    init() {}
    func dispose() {}
}
