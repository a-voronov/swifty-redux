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

    func testDeinitAfterSubscribeAndDispatchFlow() {
        weak var store: Store<State>?
        var disposable: Disposable!

        autoreleasepool {
            let deinitStore = Store(state: initialState, reducer: nopReducer, middleware: [nopMiddleware])
            store = deinitStore
            disposable = deinitStore.subscribe(observer: { state in })
            deinitStore.dispatch("action")
            let _ = deinitStore.state 
        }

        XCTAssertNotNil(disposable)
        XCTAssertNil(store)
    }

    func testDisposablesShouldBeDisposedAfterStoreDies() {
        // 🤔
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
        let _ = store.state

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
        let _ = store.state

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
        let _ = store.state

        XCTAssertEqual(result, [1, 2, 1, 1, 3, 3, 5, 2])
    }

    func testReceiveStateUpdatesOnSelectedQueue() {
        // store.subscribe(on: queue) - queue
    }

    func testReceiveStateUpdatesOnDefaultQueueEvenIfSelectedQueuePreviously() {
        // store.subscribe(on: queue)
        // store.subscribe() - default
    }

    func testStopReceivingStateUpdatesWhenUnsubscribing() {

    }

    func testStartReceivingStateUpdatesWhenSubscribingToObserver() {

    }

    func testStopReceivingStateUpdatesWhenUnsubscribingFromObserver() {

    }
}
