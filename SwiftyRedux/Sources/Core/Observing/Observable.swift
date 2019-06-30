import Dispatch

/// Observable represents a push style sequence.
///
/// Subscribe to value updates using `subscribe` method and stop listening updates using disposable.
/// All observers are removed and all disposables are disposed when observable dies.
public final class Observable<Value> {

    /// Unique identifier, used to mark internal atomic observers set, composite disposable and observers' disposables.
    private let id: String

    /// Composite disposable to hold observers' disposables.
    private let disposables: CompositeDisposable

    /// Atomic set of observers.
    private let observers: Atomic<Set<Observer<Value>>>

    /// Initializes with unique id and an observable manipulation function.
    ///
    /// - Parameters:
    ///     - id: Unique identifier. Mostly used for internal queue label and debugging purposes. Defaults to `nil`.
    ///     - observable: A function to manipulate observable and send values here from the caller.
    ///         Receives callback with value updates, returns disposable to stop observing value updates.
    ///         Can be used for direct observable implementation, as well as for observables binding.
    ///     - handler: A function to send values from the caller.
    ///     - value: Value to send.
    public init(id: String? = nil, observable: (_ handler: @escaping (_ value: Value) -> Void) -> Disposable?) {
        self.id = id ?? "swifty-redux.observable"
        self.observers = Atomic(id: self.id, value: Set())
        self.disposables = CompositeDisposable(id: "\(self.id).composite-disposable")
        self.disposables += observable { value in
            let currentObservers = self.observers.value
            currentObservers.forEach { observer in observer.update(value) }
        }
    }

    /// Initializes with unique id and an observable.
    ///
    /// - Parameters:
    ///     - id: Unique identifier. Mostly used for internal queue label and debugging purposes. Defaults to `nil`.
    ///     - observable: Another observable to bind to.
    public convenience init(id: String? = nil, observable: Observable<Value>) {
        self.init(id: id, observable: { observable.subscribe(observer: $0) })
    }

    /// Subscribes a value update observer.
    ///
    /// You can stop listening to updates by calling `dispose()` on returned disposable.
    /// Once disposable is disposed, it will be removed from composite disposable and observer will be removed as well.
    ///
    /// - Parameters:
    ///     - observingQueue: A queue on which to asynchronously receive updates. Defaults to `nil`.
    ///     - observer: Callback that will receive new values.
    ///     - value: New value.
    @discardableResult
    public func subscribe(on observingQueue: DispatchQueue? = nil, observer: @escaping (_ value: Value) -> Void) -> Disposable {
        let observer = Observer(queue: observingQueue, update: observer)
        return subscribe(observer: observer)
    }

    /// Subscribes a value update observer.
    ///
    /// You can stop listening to updates by calling `dispose()` on returned disposable.
    /// Once disposable is disposed, it will be removed from composite disposable and observer will be removed as well.
    ///
    /// - Parameters:
    ///     - observer: Value observer.
    @discardableResult
    public func subscribe(observer: Observer<Value>) -> Disposable {
        observers.mutate { $0.insert(observer) }
        var disposable: Disposable!
        disposable = Disposable(id: "\(id).disposable") { [weak self, weak observer] in
            guard let strongSelf = self, let observer = observer else { return }
            strongSelf.observers.mutate { $0.remove(observer) }
            // kinda optimization not to store all the disposables (in case this Observable is intended for Store)
            disposable.map(strongSelf.disposables.remove)
        }
        return disposables += disposable
    }

    deinit {
        disposables.dispose()
        observers.mutate { $0.removeAll() }
    }
}

extension Observable {

    /// Create an observable that will be controlled by sending values to an input observer.
    ///
    /// - Parameters:
    ///     - id: Unique identifier. Mostly used for internal queue label and debugging purposes. Defaults to `nil`.
    ///     - queue: A queue on which to asynchronously receive updates inside observable. Defaults to `nil`.
    ///     - disposable: An optional disposable to associate with the observable, and to be disposed of when observable dies.
    /// - Returns: A 2-tuple of the output end of the pipe as `Observable`, and the input end of the pipe as `Observer`.
    ///
    /// - Note: It's recomended to use this method when creating `Observable` as it simplifies things
    ///     by providing both input to send updates to and output to listen to these updates.
    public static func pipe(id: String? = nil, queue: DispatchQueue? = nil, disposable: Disposable? = nil) -> (output: Observable, input: Observer<Value>) {
        var observer: Observer<Value>!
        let observable = Observable(id: id) { action in
            observer = Observer(queue: queue, update: action)
            return disposable
        }
        return (observable, observer)
    }
}
