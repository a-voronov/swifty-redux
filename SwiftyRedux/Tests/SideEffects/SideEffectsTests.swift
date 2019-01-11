import XCTest
@testable import SwiftyRedux

private typealias State = Int
private enum AnyAction: Action, Equatable {
    case one, two, three
}

private class MockSideEffect {
    private(set) var calledWithStoreCount: Int = 0
    private(set) var calledWithAction: [Action] = []
    private(set) var sideEffect: SideEffect<State>!

    init() {
        sideEffect = { getState, dispatch in
            self.calledWithStoreCount += 1
            return { action in
                self.calledWithAction.append(action)
            }
        }
    }
}

class SideEffectsTests: XCTestCase {
    func testCombineSideEffectCallsEachSideEffectOnce() {
        let action = AnyAction.one
        let mock1 = MockSideEffect()
        let mock2 = MockSideEffect()
        let mock3 = MockSideEffect()
        let sideEffect = combineSideEffects(mock1.sideEffect, mock2.sideEffect, mock3.sideEffect)

        _ = sideEffect({ 0 }, { _ in })(action)

        XCTAssertEqual(mock1.calledWithAction.count, 1)
        XCTAssertEqual(mock2.calledWithAction.count, 1)
        XCTAssertEqual(mock3.calledWithAction.count, 1)
        XCTAssertEqual(mock1.calledWithAction.first as! AnyAction, action)
        XCTAssertEqual(mock2.calledWithAction.first as! AnyAction, action)
        XCTAssertEqual(mock3.calledWithAction.first as! AnyAction, action)
    }

    func testSideEffectMiddlewareCanGetState() {
        var result: State?
        let middleware: Middleware<State> = createSideEffectMiddleware { getState, dispatch in
            return { action in result = getState() }
        }
        let dispatch = middleware({ 42 }, { _ in }, { _ in })

        dispatch(AnyAction.one)

        XCTAssertEqual(result, 42)
    }

    func testSideEffectMiddlewareCanDispatch() {
        var result: AnyAction?
        let middleware: Middleware<State> = createSideEffectMiddleware { getState, dispatch in
            return { action in
                if action as! AnyAction == .one {
                    dispatch(AnyAction.two)
                }
            }
        }
        let dispatch = middleware({ 0 }, { action in result = action as? AnyAction }, { _ in })

        dispatch(AnyAction.one)

        XCTAssertEqual(result, .two)
    }

    func testSideEffectMiddlewareStoreCallbackIsCalledOnce() {
        let mock = MockSideEffect()
        let middleware = createSideEffectMiddleware(mock.sideEffect)
        let dispatch = middleware({ 0 }, { _ in }, { _ in })

        dispatch(AnyAction.one)
        dispatch(AnyAction.two)
        dispatch(AnyAction.three)

        XCTAssertEqual(mock.calledWithStoreCount, 1)
        XCTAssertEqual(mock.calledWithAction.count, 3)
    }

    func testSideEffectMiddlewareNextIsCalledBeforeSideEffect() {
        enum Call: Equatable { case next, action }
        var result = [Call]()
        let middleware: Middleware<State> = createSideEffectMiddleware { getState, dispatch in
            return { action in
                result.append(.action)
            }
        }
        let dispatch = middleware({ 0 }, { _ in }, { action in result.append(.next) })

        dispatch(AnyAction.one)

        XCTAssertEqual(result, [.next, .action])
    }
}
