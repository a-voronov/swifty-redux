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
/// Will serially execute action and toggle `isDisposed` flag.

public final class Disposable {
    private let lock = Lock()
    private var action: (() -> Void)?
    internal var onDisposed: (() -> Void)?

    private var _isDisposed: Bool = false
    public var isDisposed: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isDisposed
    }

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public func dispose() {
        func tryDispose() -> Bool {
            lock.lock(); defer { lock.unlock() }
            guard !_isDisposed else { return false }
            _isDisposed = true
            return true
        }
        if tryDispose() {
            action?()
            action = nil
            onDisposed?()
        }
    }

    public static func nop() -> Disposable {
        return Disposable()
    }

    private init() {
        self.action = nil
        self._isDisposed = true
    }
}

extension Disposable: Hashable {
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    public static func == (left: Disposable, right: Disposable) -> Bool {
        return left === right
    }
}

public final class CompositeDisposable {
    private let lock = Lock()
    private var disposables: Set<Disposable>?

    private var _isDisposed: Bool {
        return disposables == nil
    }
    public var isDisposed: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isDisposed
    }

    internal init(disposables: Set<Disposable>) {
        self.disposables = disposables
    }

    public convenience init() {
        self.init(disposables: Set())
    }

    public convenience init(disposing disposables: Disposable...) {
        self.init(disposables: Set(disposables))
    }

    public convenience init(disposing disposables: [Disposable]) {
        self.init(disposables: Set(disposables))
    }

    public func add(_ disposable: Disposable) {
        lock.lock(); defer { lock.unlock() }
        guard !_isDisposed else {
            return disposable.dispose()
        }
        disposables?.insert(disposable)
    }

    public func remove(_ disposable: Disposable) {
        lock.lock(); defer { lock.unlock() }
        disposables?.remove(disposable)
    }

    public func add(_ disposables: [Disposable]) {
        lock.lock(); defer { lock.unlock() }
        guard !_isDisposed else {
            return disposables.forEach { $0.dispose() }
        }
        self.disposables?.formUnion(Set(disposables))
    }

    public func dispose() {
        lock.lock()
        let currentDisposables = disposables
        disposables?.removeAll(keepingCapacity: false)
        disposables = nil
        lock.unlock()

        currentDisposables?.forEach { $0.dispose() }
    }
}

extension CompositeDisposable {
    @discardableResult
    public static func += (lhs: CompositeDisposable, rhs: Disposable) -> Disposable {
        lhs.add(rhs)
        return rhs
    }

    @discardableResult
    public static func += (lhs: CompositeDisposable, rhs: Disposable?) -> Disposable? {
        rhs.map(lhs.add)
        return rhs
    }

    @discardableResult
    public static func += (lhs: CompositeDisposable, rhs: @escaping () -> Void) -> Disposable {
        let disposable = Disposable(action: rhs)
        lhs.add(disposable)
        return disposable
    }
}
