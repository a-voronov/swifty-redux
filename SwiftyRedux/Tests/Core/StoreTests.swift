import XCTest
@testable import SwiftyRedux

private typealias State = Int

private enum AnyAction: Int, Action { case one = 1, two, three, four, five }
private enum OpAction: Action, Equatable { case inc, mul }
private struct StringAction: Action {
    let value: String
    init(_ value: String) { self.value = value }
}

private class MockMiddleware {
    private(set) var calledWithStoreCount: Int = 0
    private(set) var calledWithAction: [Action] = []
    private(set) var middleware: Middleware<State>!

    init() {
        middleware = createMiddleware { getState, dispatch, next in
            self.calledWithStoreCount += 1
            return { action in
                self.calledWithAction.append(action)
                next(action)
            }
        }
    }
}
private class MockFallThroughMiddleware {
    private(set) var calledWithStoreCount: Int = 0
    private(set) var calledWithAction: [Action] = []
    private(set) var middleware: Middleware<State>!

    init() {
        middleware = createFallThroughMiddleware { getState, dispatch in
            self.calledWithStoreCount += 1
            return { action in
                self.calledWithAction.append(action)
            }
        }
    }
}

class StoreTests: XCTestCase {
    private var initialState: State!
    private var nopReducer: Reducer<State>!
    private var nopMiddleware: Middleware<State>!

    override func setUp() {
        super.setUp()

        initialState = 0
        nopReducer = { action, state in state }
        nopMiddleware = createFallThroughMiddleware { getState, dispatch in return { action in } }
    }

    func testMiddlewareIsExecutedOnlyOnceBeforeActionReceived() {
        let mock = MockMiddleware()
        let store = Store(state: initialState, reducer: nopReducer, middleware: [mock.middleware])

        store.dispatch(AnyAction.one)
        store.dispatch(AnyAction.two)
        store.dispatch(AnyAction.three)

        XCTAssertEqual(mock.calledWithStoreCount, 1)
    }

    func testFallThroughMiddlewareIsExecutedOnlyOnceBeforeActionReceived() {
        let mock = MockFallThroughMiddleware()
        let store = Store(state: initialState, reducer: nopReducer, middleware: [mock.middleware])

        store.dispatch(AnyAction.one)
        store.dispatch(AnyAction.two)
        store.dispatch(AnyAction.three)

        XCTAssertEqual(mock.calledWithStoreCount, 1)
    }

    func testMiddlewareExecutesActionBodyAsManyTimesAsActionsReceived() {
        let mock = MockMiddleware()
        let store = Store(state: initialState, reducer: nopReducer, middleware: [mock.middleware])

        store.dispatch(AnyAction.one)
        store.dispatch(AnyAction.two)
        store.dispatchAndWait(AnyAction.three)

        XCTAssertEqual(mock.calledWithAction.count, 3)
    }

    func testFallThroughMiddlewareExecutesActionBodyAsManyTimesAsActionsReceived() {
        let mock = MockMiddleware()
        let store = Store(state: initialState, reducer: nopReducer, middleware: [mock.middleware])

        store.dispatch(AnyAction.one)
        store.dispatch(AnyAction.two)
        store.dispatchAndWait(AnyAction.three)

        XCTAssertEqual(mock.calledWithAction.count, 3)
    }

    func testStore_whenDispatchingWithoutWaiting_shouldPerformAsynchronously() {
        var result: State = 0
        let asyncExpectation = expectation(description: "testStore_whenDispatchingWithoutWaiting_shouldPerformAsynchronously")
        let store = Store(state: 42, reducer: nopReducer, middleware: [nopMiddleware])
        store.subscribe { state in
            result = state
            asyncExpectation.fulfill()
        }

        store.dispatch(AnyAction.one)

        // not yet
        XCTAssertEqual(result, 0)
        waitForExpectations(timeout: 0.1) { e in
            // here we go
            XCTAssertEqual(result, 42)
        }
    }

    func testStore_whenDispatchingAndWaiting_shouldPerformSynchronously() {
        var result: State = 0
        let store = Store(state: 42, reducer: nopReducer, middleware: [nopMiddleware])
        store.subscribe { state in
            result = state
        }

        store.dispatchAndWait(AnyAction.one)

        XCTAssertEqual(result, 42)
    }

    func testStore_afterSubscribeAndDispatchFlow_deinits_andAllDisposablesDispose() {
        weak var store: Store<State>?
        var disposable: Disposable!

        autoreleasepool {
            let deinitStore = Store(state: initialState, reducer: nopReducer, middleware: [nopMiddleware])
            store = deinitStore
            disposable = deinitStore.subscribe(observer: { state in })
            deinitStore.dispatchAndWait(AnyAction.one)
        }

        XCTAssertTrue(disposable.isDisposed)
        XCTAssertNil(store)
    }

    func testMiddleware_whenRunOnDefaultQueue_isExecutedSequentiallyWithReducer() {
        var result = [String]()
        let middleware: Middleware<State> = createMiddleware { getState, dispatch, next in
            return { action in
                result.append("m-\(action)")
                next(action)
            }
        }
        let reducer: Reducer<State> = { action, state in
            result.append("r-\(action)")
            return state
        }
        let store = Store<State>(state: initialState, reducer: reducer, middleware: [middleware])

        store.dispatch(AnyAction.one)
        store.dispatch(AnyAction.two)
        store.dispatch(AnyAction.three)
        store.dispatchAndWait(AnyAction.four)

        XCTAssertEqual(result, ["m-one", "r-one", "m-two", "r-two", "m-three", "r-three", "m-four", "r-four"])
    }

    func testMiddleware_evenIfRunOnDifferentQueues_isExecutedSequentially() {
        func asyncMiddleware(id: String, qos: DispatchQoS.QoSClass) -> Middleware<State> {
            let asyncExpectation = expectation(description: "\(id) async middleware expectation")
            return createMiddleware { getState, dispatch, next in
                return { action in
                    DispatchQueue.global(qos: qos).async {
                        let action = (action as! StringAction).value
                        next(StringAction("\(action) \(id)"))
                        asyncExpectation.fulfill()
                    }
                }
            }
        }

        var result = ""
        let reducer: Reducer<State> = { action, state in
            let action = (action as! StringAction).value
            result += action
            return state
        }
        let middleware1 = asyncMiddleware(id: "first", qos: .default)
        let middleware2 = asyncMiddleware(id: "second", qos: .userInteractive)
        let middleware3 = asyncMiddleware(id: "third", qos: .background)
        let store = Store<State>(state: initialState, reducer: reducer, middleware: [middleware1, middleware2, middleware3])

        store.dispatch(StringAction("action"))

        waitForExpectations(timeout: 1) { e in
            XCTAssertEqual(result, "action first second third")
        }
    }

    func testStore_whenSubscribing_startReceivingStateUpdates() {
        let reducer: Reducer<State> = { action, state in
            switch action {
            case let action as OpAction where action == OpAction.mul: return state * 2
            case let action as OpAction where action == OpAction.inc: return state + 3
            default: return state
            }
        }
        let store = Store<State>(state: 3, reducer: reducer)

        var result: [State] = []
        store.subscribe { state in
            result.append(state)
        }
        store.dispatch(OpAction.mul)
        store.dispatchAndWait(OpAction.inc)

        XCTAssertEqual(result, [6, 9])
    }

    func testSubscribeToStore_whenSkippingRepeats_receiveUniqueStateUpdates() {
        let actions: [AnyAction] = [.one, .two, .one, .one, .three, .three, .five, .two]
        let reducer: Reducer<State> = { action, state in
            (action as! AnyAction).rawValue
        }
        let store = Store<State>(state: initialState, reducer: reducer)

        var result: [State] = []
        store.subscribe(skipRepeats: true) { state in
            result.append(state)
        }
        actions.forEach(store.dispatchAndWait)

        XCTAssertEqual(result, [1, 2, 1, 3, 5, 2])
    }

    func testSubscribeToStore_whenNotSkippingRepeats_receiveDuplicatedStateUpdates() {
        let actions: [AnyAction] = [.one, .two, .one, .one, .three, .three, .five, .two]
        let reducer: Reducer<State> = { action, state in
            (action as! AnyAction).rawValue
        }
        let store = Store<State>(state: initialState, reducer: reducer)

        var result: [State] = []
        store.subscribe(skipRepeats: false) { state in
            result.append(state)
        }
        actions.forEach(store.dispatchAndWait)

        XCTAssertEqual(result, [1, 2, 1, 1, 3, 3, 5, 2])
    }

    func testStore_whenSubscribing_ReceiveStateUpdatesOnSelectedQueue() {
        let id = "testStore_whenSubscribing_ReceiveStateUpdatesOnSelectedQueue"
        let queueId = DispatchSpecificKey<String>()
        let queue = DispatchQueue(label: id)
        queue.setSpecific(key: queueId, value: id)
        let store = Store<State>(state: initialState, reducer: nopReducer)

        var result: String!
        let queueExpectation = expectation(description: id)
        store.subscribe(on: queue) { state in
            result = DispatchQueue.getSpecific(key: queueId)
            queueExpectation.fulfill()
        }
        store.dispatch(AnyAction.one)

        waitForExpectations(timeout: 0.1) { e in
            queue.setSpecific(key: queueId, value: nil)

            XCTAssertEqual(result, id)
        }
    }

    func testStore_whenSubscribingWithoutSelectedQueue_butDidSoBefore_receiveStateUpdatesOnDefaultQueue() {
        let id = "testStore_whenSubscribingWithoutSelectedQueue_butDidSoBefore_receiveStateUpdatesOnDefaultQueue"
        let queueId = DispatchSpecificKey<String>()
        let queue = DispatchQueue(label: id)
        queue.setSpecific(key: queueId, value: id)
        let store = Store<State>(state: initialState, reducer: nopReducer)

        var result: String!
        let onQueueExpectation = expectation(description: "\(id) on queue")
        let defaultQueueExpectation = expectation(description: "\(id) default queue")
        store.subscribe(on: queue) { state in
            onQueueExpectation.fulfill()
        }
        store.subscribe { state in
            defaultQueueExpectation.fulfill()
            result = DispatchQueue.getSpecific(key: queueId)
        }
        store.dispatch(AnyAction.one)

        waitForExpectations(timeout: 0.1) { e in
            queue.setSpecific(key: queueId, value: nil)

            XCTAssertNotEqual(result, id)
        }
    }

    func testStore_whenUnsubscribing_stopReceivingStateUpdates() {
        let reducer: Reducer<State> = { action, state in
            (action as! AnyAction).rawValue
        }
        let store = Store<State>(state: initialState, reducer: reducer)

        var result: [State] = []
        let disposable = store.subscribe { state in
            result.append(state)
        }
        store.dispatch(AnyAction.one)
        store.dispatch(AnyAction.two)
        store.dispatchAndWait(AnyAction.three)

        disposable.dispose()
        store.dispatch(AnyAction.four)
        store.dispatchAndWait(AnyAction.five)

        XCTAssertEqual(result, [1, 2, 3])
    }

    func testStore_whenObserving_andSubscribingToObserver_startReceivingStateUpdates() {
        let reducer: Reducer<State> = { action, state in
            switch action {
            case let action as OpAction where action == .mul: return state * 2
            case let action as OpAction where action == .inc: return state + 3
            default: return state
            }
        }
        let store = Store<State>(state: 3, reducer: reducer)

        var result: [State] = []
        store.observe().subscribe { state in
            result.append(state)
        }
        store.dispatch(OpAction.mul)
        store.dispatchAndWait(OpAction.inc)

        XCTAssertEqual(result, [6, 9])
    }

    func testStore_whenUnsubscribingFromObserver_stopReceivingStateUpdates() {
        let reducer: Reducer<State> = { action, state in
            (action as! AnyAction).rawValue
        }
        let store = Store<State>(state: initialState, reducer: reducer)

        var result: [State] = []
        let disposable = store.observe().subscribe { state in
            result.append(state)
        }
        store.dispatch(AnyAction.one)
        store.dispatch(AnyAction.two)
        store.dispatchAndWait(AnyAction.three)

        disposable.dispose()
        store.dispatch(AnyAction.four)
        store.dispatchAndWait(AnyAction.five)

        XCTAssertEqual(result, [1, 2, 3])
    }
}
