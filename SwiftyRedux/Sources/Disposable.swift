//
//  Disposable.swift
//  SwiftyRedux
//
//  Created by Alexander Voronov on 12/16/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

/// Used to dispose from any resources when needed.
/// Initialize it with action to execute once disposal is needed.
/// Additionaly you can see whether action was already executed or not. And it won't be executed if it was already
/// Default implementation has its own queue to serially execute action and toggle `isDisposed` flag.

public protocol Disposable {
    var isDisposed: Bool { get }

    func dispose()
}

public final class DisposableAction: Disposable {
    private let queue: ReadWriteQueue
    private let action: () -> Void

    private var _isDisposed: Bool = false
    public var isDisposed: Bool {
        return queue.read { _isDisposed }
    }

    public init(id: String = "redux.disposable", action: @escaping () -> Void) {
        self.queue = ReadWriteQueue(label: "\(id).queue")
        self.action = action
    }

    public func dispose() {
        queue.write {
            guard !self._isDisposed else { return }
            self.action()
            self._isDisposed = true
        }
    }
}

public final class NopDisposable: Disposable {
    public let isDisposed: Bool = true
    public init() {}
    public func dispose() {}
}
