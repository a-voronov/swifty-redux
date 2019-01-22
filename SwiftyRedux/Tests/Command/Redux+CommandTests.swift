import XCTest
import Dispatch
@testable import SwiftyRedux

private typealias State = Int
private struct AnyAction: Action, Equatable {}

class ReduxCommandTests: XCTestCase {
    private var initialState: State!
    private var nopReducer: Reducer<State>!
    private var nopMiddleware: Middleware<State>!

    override func setUp() {
        super.setUp()

        initialState = 0
        nopReducer = { action, state in state }
        nopMiddleware = createFallThroughMiddleware { getState, dispatch in return { action in } }
    }

    // TODO: test subscribe includingCurrentState: true

    func testStore_whenSubscribingWithCommand_shouldRedirectToOriginalMethod_byCallingCommandOnSpecifiedQueueForActionDispatched() {
        let id = "testStore_whenSubscribingWithCommand_shouldRedirectToOriginalMethod_byCallingCommandOnSpecifiedQueueForActionDispatched"
        let key = DispatchSpecificKey<String>()
        let queue = DispatchQueue(label: id)
        queue.setSpecific(key: key, value: id)
        let store = Store<State>(state: initialState, reducer: nopReducer, middleware: [nopMiddleware])

        store.subscribe(on: queue, includingCurrentState: false, Command { value in
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), id)
            XCTAssertEqual(value, self.initialState)

            queue.setSpecific(key: key, value: nil)
        })

        store.dispatch(AnyAction())
    }

    func testStore_whenSubscribingWithCommand_shouldRedirectToOriginalMethod_byCallingCommandForEveryActionDispatched() {
        var result = 0
        let queue = DispatchQueue(label: "testStore_whenSubscribingWithCommand_shouldRedirectToOriginalMethod_byCallingCommandForEveryActionDispatched")
        let store = Store<State>(state: initialState, reducer: nopReducer, middleware: [nopMiddleware])

        store.subscribe(on: queue, includingCurrentState: false, Command { value in result += 1 })

        store.dispatch(AnyAction())
        store.dispatch(AnyAction())
        store.dispatchAndWait(AnyAction())

        // wait for serial queue to finish executing previous async tasks
        queue.sync {}

        XCTAssertEqual(result, 3)
    }

    func testObservable_whenSubscribingWithCommand_shouldRedirectToOriginalMethod() {
        let id = "testObservable_whenSubscribingWithCommand_shouldRedirectToOriginalMethod"
        let key = DispatchSpecificKey<String>()
        let queue = DispatchQueue(label: id)
        queue.setSpecific(key: key, value: id)
        let (observable, observer) = Observable<State>.pipe()

        observable.subscribe(on: queue, Command { value in
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), id)
            XCTAssertEqual(value, self.initialState)

            queue.setSpecific(key: key, value: nil)
        })

        observer.update(initialState)
    }

    func testObserver_whenInitializedWithCommand_shouldRedirectToDesignatedInitializer() {
        let id = "testObserver_whenInitializedWithCommand_shouldRedirectToDesignatedInitializer"
        let key = DispatchSpecificKey<String>()
        let queue = DispatchQueue(label: id)
        queue.setSpecific(key: key, value: id)

        let observer = Observer<State>(queue: queue, Command { value in
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), id)
            XCTAssertEqual(value, self.initialState)

            queue.setSpecific(key: key, value: nil)
        })

        observer.update(initialState)
    }

    func testDisposable_whenInitializedWithCommand_shouldRedirectToDesignatedInitializer() {
        let disposable1 = Disposable(Command {
            XCTAssertTrue(true)
        })
        disposable1.dispose()

        var weakDisposable2: Disposable?
        let disposable2 = Disposable(Command { (d: Disposable?) in
            weakDisposable2 = d
            XCTAssertTrue(true)
        })
        disposable2.dispose()

        XCTAssertEqual(disposable2, weakDisposable2)
    }
}
