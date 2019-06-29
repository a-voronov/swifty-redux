import Dispatch

/// Just an implementation of Observable.
/// You can initialize it with another observable as an instance of this class or as an anonymous function.
/// It has its own queue to manage observers list modifications and sending updates in a serial way.
/// You can apply any of available transforming or filtering functions to only receive updates you're interested in.
/// Once you're ready, call `subscribe` method to pass observer - you'll be returned `Disposable` to stop listening for updates.
///
/// There's also handy function `pipe` that gives you both:
/// - `observable` to listen to updates
/// - `observer` to send updates to, so that observable would get them and propagate to its observers.

public final class Observable<Value> {
    private let id: String
    private let disposables: CompositeDisposable
    private let observers: Atomic<Set<Observer<Value>>>

    public init(id: String? = nil, observable: (@escaping (Value) -> Void) -> Disposable?) {
        self.id = id ?? "swifty-redux.observable"
        self.observers = Atomic(id: self.id, value: Set())
        self.disposables = CompositeDisposable(id: "\(self.id).composite-disposable")
        self.disposables += observable { value in
            let currentObservers = self.observers.value
            currentObservers.forEach { observer in observer.update(value) }
        }
    }

    public convenience init(id: String? = nil, observable: Observable<Value>) {
        self.init(id: id, observable: { observable.subscribe(observer: $0) })
    }

    @discardableResult
    public func subscribe(on observingQueue: DispatchQueue? = nil, observer: @escaping (Value) -> Void) -> Disposable {
        let observer = Observer(queue: observingQueue, update: observer)
        return subscribe(observer: observer)
    }

    @discardableResult
    public func subscribe(observer: Observer<Value>) -> Disposable {
        observers.mutate { $0.insert(observer) }

        return disposables += Disposable(id: "\(id).disposable") { [weak self, weak observer] disposable in
            guard let strongSelf = self, let observer = observer else { return }
            strongSelf.observers.mutate { $0.remove(observer) }
            // kinda optimization not to store all the disposables (in case this Observable is intended for Store)
            disposable.map(strongSelf.disposables.remove)
        }
    }

    deinit {
        disposables.dispose()
        observers.mutate { $0.removeAll() }
    }
}

extension Observable {
    public static func pipe(id: String? = nil, queue: DispatchQueue? = nil, disposable: Disposable? = nil) -> (Observable, Observer<Value>) {
        var observer: Observer<Value>!
        let observable = Observable(id: id) { action in
            observer = Observer(queue: queue, update: action)
            return disposable
        }
        return (observable, observer)
    }
}
