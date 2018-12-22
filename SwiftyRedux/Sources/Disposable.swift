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

public final class ActionDisposable: Disposable {
    private let queue: DispatchQueue
    private var action: (() -> Void)?

    private var _isDisposed: Bool = false
    public var isDisposed: Bool {
        return queue.sync { _isDisposed }
    }

    public init(id: String? = nil, action: @escaping () -> Void) {
        self.queue = DispatchQueue(label: (id ?? "redux.disposable") + ".queue", attributes: .concurrent)
        self.action = action
    }

    public func dispose() {
        let shouldRunAction: Bool = queue.sync(flags: .barrier) {
            guard !self._isDisposed else { return false }
            self._isDisposed = true
            return true
        }
        if shouldRunAction {
            action?()
            action = nil
        }
    }
}

public final class NopDisposable: Disposable {
    public let isDisposed: Bool = true
    public init() {}
    public func dispose() {}
}

public final class DisposeBag {
    private let queue = DispatchQueue(label: "redux.dispose-bag.queue")
    private var isDisposed = false
    private var disposables: [Disposable] = []

    public init() {}

    public init(disposing disposables: Disposable...) {
        self.disposables += disposables
    }

    public init(disposing disposables: [Disposable]) {
        self.disposables += disposables
    }

    public func add(_ disposable: Disposable) {
        queue.sync {
            guard !isDisposed else {
                return disposable.dispose()
            }
            disposables.append(disposable)
        }
    }

    public func add(_ disposables: [Disposable]) {
        queue.sync {
            guard !self.isDisposed else {
                return disposables.forEach { $0.dispose() }
            }
            self.disposables += disposables
        }
    }

    private func dispose() {
        let oldDisposables: [Disposable] = queue.sync {
            let oldDisposables = disposables
            disposables.removeAll(keepingCapacity: false)
            isDisposed = true
            return oldDisposables
        }
        oldDisposables.forEach { $0.dispose() }
    }

    deinit {
        dispose()
    }
}

extension DisposeBag {
    @discardableResult
    public static func += (lhs: DisposeBag, rhs: Disposable) -> Disposable {
        lhs.add(rhs)
        return rhs
    }

    @discardableResult
    public static func += (lhs: DisposeBag, rhs: @escaping () -> Void) -> Disposable {
        let disposable = ActionDisposable(action: rhs)
        lhs.add(disposable)
        return disposable
    }
}
