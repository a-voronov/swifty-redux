import XCTest
@testable import SwiftyRedux

private typealias State = Int
private struct AnyAction: Action, Equatable {}

private class MockReducer {
    private(set) var calledWithAction: [Action] = []
    private(set) var reducer: Reducer<State>!

    init() {
        reducer = { state, action in
            self.calledWithAction.append(action)
            return state
        }
    }
}

private let multiplyByTwoReducer: Reducer<State> = { state, action in state * 2 }
private let increaseByThreeReducer: Reducer<State> = { state, action in state + 3 }

class ReducerTests: XCTestCase {
    func testCallsReducersOnce() {
        let action = AnyAction()
        let mock1 = MockReducer()
        let mock2 = MockReducer()
        let reducer = combineReducers(mock1.reducer, mock2.reducer)

        _ = reducer(0, action)

        XCTAssertEqual(mock1.calledWithAction.count, 1)
        XCTAssertEqual(mock2.calledWithAction.count, 1)
        XCTAssertEqual(mock1.calledWithAction.first as! AnyAction, action)
        XCTAssertEqual(mock2.calledWithAction.first as! AnyAction, action)
    }

    func testCombinedReducerResultsCorrectly() {
        let reducer = combineReducers(multiplyByTwoReducer, increaseByThreeReducer)
        let newState = reducer(3, AnyAction())

        XCTAssertEqual(newState, 9)
    }
}
