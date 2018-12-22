//
//  StoreTests.swift
//  SwiftyReduxTests
//
//  Created by Alexander Voronov on 12/16/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

import XCTest
@testable import SwiftyRedux

private typealias State = Int
private typealias StringAction = String

class StoreTests: XCTestCase {
    private var initialState: State!
    private var nopAction: StringAction = ""
    private var nopReducer: Reducer<State>!
    private var nopMiddleware: Middleware<State>!

    override func setUp() {
        super.setUp()

        initialState = 0
        nopAction = "action"
        nopReducer = { action, state in state }
        nopMiddleware = createMiddleware(sideEffect: { getState, dispatch, action in })
    }

    func testStoreDeinitsAndAllDisposablesDisposeAfterSubscribeAndDispatchFlow() {
        weak var store: Store<State>?
        var disposable: Disposable!

        autoreleasepool {
            let deinitStore = Store(state: initialState, reducer: nopReducer, middleware: [nopMiddleware])
            store = deinitStore
            disposable = deinitStore.subscribe(observer: { state in })
            deinitStore.dispatch("action")
            _ = deinitStore.state 
        }

        XCTAssertTrue(disposable.isDisposed)
        XCTAssertNil(store)
    }

    func testMiddlewareIsExecutedSequentiallyEvenIfRunOnDifferentQueues() {
        func asyncMiddleware(id: String, qos: DispatchQoS.QoSClass) -> Middleware<State> {
            let asyncExpectation = expectation(description: "\(id) async middleware expectation")
            return createMiddleware { getState, dispatch, next in
                return { action in
                    DispatchQueue.global(qos: qos).async {
                        next("\(action) \(id)");
                        asyncExpectation.fulfill()
                    }
                }
            }
        }

        var result = ""
        let reducer: Reducer<State> = { action, state in
            result += action as! StringAction
            return state
        }
        let middleware1 = asyncMiddleware(id: "first", qos: .default)
        let middleware2 = asyncMiddleware(id: "second", qos: .userInteractive)
        let middleware3 = asyncMiddleware(id: "third", qos: .background)
        let store = Store<State>(state: initialState, reducer: reducer, middleware: [middleware1, middleware2, middleware3])

        store.dispatch(nopAction)

        waitForExpectations(timeout: 0.1) { e in
            XCTAssertEqual(result, "action first second third")
        }
    }

    func testStartReceivingStateUpdatesWhenSubscribing() {
        let reducer: Reducer<State> = { action, state in
            switch action {
            case let action as StringAction where action == "mul": return state * 2
            case let action as StringAction where action == "inc": return state + 3
            default: return state
            }
        }
        let store = Store<State>(state: 3, reducer: reducer)

        var result: [State] = []
        store.subscribe { state in
            result.append(state)
        }
        store.dispatch("mul")
        store.dispatch("inc")
        // reading state to wait on a calling thread until writing tasks complete
        _ = store.state

        XCTAssertEqual(result, [6, 9])
    }

    func testReceiveUniqueStateUpdatesWhenSkippingRepeats() {
        let actions: [StringAction] = ["1", "2", "1", "1", "3", "3", "5", "2"]
        let reducer: Reducer<State> = { action, state in
            Int(action as! StringAction)!
        }
        let store = Store<State>(state: initialState, reducer: reducer)

        var result: [State] = []
        store.subscribe(skipRepeats: true) { state in
            result.append(state)
        }
        actions.forEach(store.dispatch)
        // reading state to wait on a calling thread until writing tasks complete
        _ = store.state

        XCTAssertEqual(result, [1, 2, 1, 3, 5, 2])
    }

    func testReceiveDuplicatedStateUpdatesWhenNotSkippingRepeats() {
        let actions: [StringAction] = ["1", "2", "1", "1", "3", "3", "5", "2"]
        let reducer: Reducer<State> = { action, state in
            Int(action as! StringAction)!
        }
        let store = Store<State>(state: initialState, reducer: reducer)

        var result: [State] = []
        store.subscribe(skipRepeats: false) { state in
            result.append(state)
        }
        actions.forEach(store.dispatch)
        // reading state to wait on a calling thread until writing tasks complete
        _ = store.state

        XCTAssertEqual(result, [1, 2, 1, 1, 3, 3, 5, 2])
    }

    func testReceiveStateUpdatesOnSelectedQueue() {
        let id = "testReceiveStateUpdatesOnSelectedQueue"
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
        store.dispatch(nopAction)

        waitForExpectations(timeout: 0.1) { e in
            queue.setSpecific(key: queueId, value: nil)

            XCTAssertEqual(result, id)
        }
    }

    func testReceiveStateUpdatesOnDefaultQueueEvenIfSelectedQueuePreviously() {
        let id = "testReceiveStateUpdatesOnSelectedQueue"
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
        store.dispatch(nopAction)

        waitForExpectations(timeout: 0.1) { e in
            queue.setSpecific(key: queueId, value: nil)

            XCTAssertNotEqual(result, id)
        }
    }

    func testStopReceivingStateUpdatesWhenUnsubscribing() {
        let reducer: Reducer<State> = { action, state in
            return Int(action as! StringAction)!
        }
        let store = Store<State>(state: initialState, reducer: reducer)

        var result: [State] = []
        let disposable = store.subscribe { state in
            result.append(state)
        }
        store.dispatch("1")
        store.dispatch("2")
        store.dispatch("3")
        // reading state to wait on a calling thread until writing tasks complete
        _ = store.state
        disposable.dispose()
        store.dispatch("4")
        store.dispatch("5")
        // reading state to wait on a calling thread until writing tasks complete
        _ = store.state

        XCTAssertEqual(result, [1, 2, 3])
    }

    func testStartReceivingStateUpdatesWhenSubscribingToObserver() {
        let reducer: Reducer<State> = { action, state in
            switch action {
            case let action as StringAction where action == "mul": return state * 2
            case let action as StringAction where action == "inc": return state + 3
            default: return state
            }
        }
        let store = Store<State>(state: 3, reducer: reducer)

        var result: [State] = []
        store.observe().subscribe { state in
            result.append(state)
        }
        store.dispatch("mul")
        store.dispatch("inc")
        // reading state to wait on a calling thread until writing tasks complete
        _ = store.state

        XCTAssertEqual(result, [6, 9])
    }

    func testStopReceivingStateUpdatesWhenUnsubscribingFromObserver() {
        let reducer: Reducer<State> = { action, state in
            return Int(action as! StringAction)!
        }
        let store = Store<State>(state: initialState, reducer: reducer)

        var result: [State] = []
        let disposable = store.observe().subscribe { state in
            result.append(state)
        }
        store.dispatch("1")
        store.dispatch("2")
        store.dispatch("3")
        // reading state to wait on a calling thread until writing tasks complete
        _ = store.state
        disposable.dispose()
        store.dispatch("4")
        store.dispatch("5")
        // reading state to wait on a calling thread until writing tasks complete
        _ = store.state

        XCTAssertEqual(result, [1, 2, 3])
    }
}
