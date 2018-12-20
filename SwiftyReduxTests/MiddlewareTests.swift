//
//  MiddlewareTests.swift
//  SwiftyReduxTests
//
//  Created by Alexander Voronov on 12/16/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

import XCTest
@testable import SwiftyRedux

private typealias State = Int
private typealias StringAction = String

class MiddlewareTests: XCTestCase {
    private var initialState: State!
    private var nopAction: StringAction = ""
    private var nopReducer: Reducer<State>!

    override func setUp() {
        super.setUp()

        initialState = 0
        nopAction = "action"
        nopReducer = { action, state in state }
    }

    func testAppliedMiddlewareIsChainedInCorrectOrder() {
        var result: StringAction!
        let middleware: Middleware<State> = applyMiddleware([
            createMiddleware { getState, dispatch, next in
                return { action in next(action as! StringAction + " first") }
            },
            createMiddleware { getState, dispatch, next in
                return { action in next(action as! StringAction + " second") }
            },
            createMiddleware { getState, dispatch, next in
                return { action in next(action as! StringAction + " third") }
            }
        ])

        middleware({ self.initialState }, { _ in }, { action in result = action as? StringAction })(nopAction)

        XCTAssertEqual(result, "\(nopAction) first second third")
    }

    func testSideEffectMiddlewarePropagatesActionToTheNextOne() {
        var result: StringAction = ""
        let middleware: Middleware<State> = applyMiddleware([
            createMiddleware(sideEffect: { getState, dispatch, action in
                result += (action as! StringAction) + " first "
            }),
            createMiddleware(sideEffect: { getState, dispatch, action in
                result += (action as! StringAction) + " second"
            })
        ])

        middleware({ self.initialState }, { _ in }, { _ in })(nopAction)

        XCTAssertEqual(result, "\(nopAction) first \(nopAction) second")
    }

    func testCanGetState() {
        var result: State!
        let middleware: Middleware<State> = createMiddleware(sideEffect: { getState, dispatch, action in
            result = getState()
        })
        let store = Store<State>(state: initialState, reducer: nopReducer, middleware: [middleware])
        store.dispatch(nopAction)

        XCTAssertEqual(result, initialState)
    }

    func testCanDispatch() {
        var result: StringAction!
        let middleware: Middleware<State> = createMiddleware(sideEffect: { getState, dispatch, action in
            if (action as! StringAction) == self.nopAction {
                dispatch("new " + (action as! StringAction))
            } else {
                result = action as? StringAction
            }
        })
        let store = Store<State>(state: initialState, reducer: nopReducer, middleware: [middleware])
        store.dispatch(nopAction)

        XCTAssertEqual(result, "new \(nopAction)")
    }

    func testSkipsActionIfPreviousDontPropagateNext() {
        let store = Store<State>(state: initialState, reducer: nopReducer, middleware: [
            createMiddleware { getState, dispatch, next in
                return { action in }
            },
            createMiddleware { getState, dispatch, action in
                XCTFail()
            }
        ])
        store.dispatch(nopAction)
    }

    func testCanPropagateActionToNextMiddleware() {
        var result: StringAction!
        let store = Store<State>(state: initialState, reducer: nopReducer, middleware: [
            createMiddleware { getState, dispatch, next in
                return { action in next(action as! StringAction + " next") }
            },
            createMiddleware { getState, dispatch, action in
                result = action as? StringAction
            }
        ])
        store.dispatch(nopAction)

        XCTAssertEqual(result, "\(nopAction) next")
    }

    func testChangesStateAfterPropagatingToTheNextMiddleware() {
        let reducer: Reducer<State> = { action, state in
            state + Int(action as! String)!
        }
        let store = Store<State>(state: initialState, reducer: reducer, middleware: [
            createMiddleware { getState, dispatch, next in
                return { action in
                    XCTAssertEqual(getState(), self.initialState)
                    next("42")
                    XCTAssertEqual(getState(), 42)
                }
            }
        ])
        store.dispatch(nopAction)

        XCTAssertEqual(store.state, 42)
    }
}
