import XCTest
@testable import SwiftyRedux

private typealias State = Int
private struct StringAction: Action, Equatable {
    let value: String
    init(_ value: String) { self.value = value }
}

private func + (lhs: StringAction, rhs: String) -> StringAction { return StringAction(lhs.value + rhs) }
private func + (lhs: String, rhs: StringAction) -> StringAction { return rhs + lhs }

class MiddlewareTests: XCTestCase {
    private var initialState: State!
    private var nopAction: StringAction!
    private var nopReducer: Reducer<State>!

    override func setUp() {
        super.setUp()

        initialState = 0
        nopAction = StringAction("action")
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

        XCTAssertEqual(result, nopAction + " first second third")
    }

    func testFallThroughMiddlewarePropagatesActionToTheNextOne() {
        var result = ""
        let middleware: Middleware<State> = applyMiddleware([
            createFallThroughMiddleware { getState, dispatch in
                return { action in result += (action as! StringAction).value + " first " }
            },
            createFallThroughMiddleware { getState, dispatch in
                return { action in result += (action as! StringAction).value + " second" }
            }
        ])

        middleware({ self.initialState }, { _ in }, { _ in })(nopAction)

        XCTAssertEqual(result, "\(nopAction.value) first \(nopAction.value) second")
    }

    func testCanGetState() {
        var result: State!
        let middleware: Middleware<State> = createFallThroughMiddleware { getState, dispatch in
            return { action in result = getState() }
        }
        let store = Store<State>(state: initialState, reducer: nopReducer, middleware: [middleware])
        store.dispatch(nopAction)

        XCTAssertEqual(result, initialState)
    }

    func testCanDispatch() {
        var result: StringAction!
        let middleware: Middleware<State> = createFallThroughMiddleware { getState, dispatch in
            return { action in
                if (action as! StringAction) == self.nopAction {
                    dispatch("new " + (action as! StringAction))
                } else {
                    result = action as? StringAction
                }
            }
        }
        let store = Store<State>(state: initialState, reducer: nopReducer, middleware: [middleware])
        store.dispatch(nopAction)

        XCTAssertEqual(result, "new " + nopAction)
    }

    func testSkipsActionIfPreviousDontPropagateNext() {
        let store = Store<State>(state: initialState, reducer: nopReducer, middleware: [
            createMiddleware { getState, dispatch, next in
                return { action in }
            },
            createFallThroughMiddleware { getState, dispatch in
                return { action in
                    XCTFail()
                }
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
            createFallThroughMiddleware { getState, dispatch in
                return { action in result = action as? StringAction }
            }
        ])
        store.dispatch(nopAction)

        XCTAssertEqual(result, nopAction + " next")
    }

    func testChangesStateAfterPropagatingToTheNextMiddleware() {
        let reducer: Reducer<State> = { action, state in
            state + Int((action as! StringAction).value)!
        }
        let store = Store<State>(state: initialState, reducer: reducer, middleware: [
            createMiddleware { getState, dispatch, next in
                return { action in
                    XCTAssertEqual(getState(), self.initialState)
                    next(StringAction("42"))
                    XCTAssertEqual(getState(), 42)
                }
            }
        ])
        store.dispatch(nopAction)

        XCTAssertEqual(store.state, 42)
    }

//    // uncomment to test call stack overflow
//    func testInfiniteCall() {
//        let middleware: Middleware<State> = createMiddleware { getState, dispatch, next in
//            return { action in
//                dispatch(action)
//            }
//        }
//        let store = Store<State>(state: initialState, reducer: nopReducer, middleware: [middleware])
//
//        store.dispatch(nopAction)
//    }
}
