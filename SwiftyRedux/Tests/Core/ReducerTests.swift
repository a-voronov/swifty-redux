//
//  ReducerTests.swift
//  SwiftyReduxTests
//
//  Created by Alexander Voronov on 12/16/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

import XCTest
@testable import SwiftyRedux

extension String: Action {}

private typealias State = Int

private class MockReducer {
    var calledWithAction: [Action] = []
    var reducer: Reducer<State>!

    init() {
        reducer = { action, state in
            self.calledWithAction.append(action)
            return state
        }
    }
}

private let multiplyByTwoReducer: Reducer<State> = { action, state in state * 2 }
private let increaseByThreeReducer: Reducer<State> = { action, state in state + 3 }


class ReducerTests: XCTestCase {
    func testCallsReducersOnce() {
        let action = "action"
        let mock1 = MockReducer()
        let mock2 = MockReducer()
        let reducer = combineReducers(mock1.reducer, mock2.reducer)

        _ = reducer(action, 0)

        XCTAssertEqual(mock1.calledWithAction.count, 1)
        XCTAssertEqual(mock2.calledWithAction.count, 1)
        XCTAssertEqual(mock1.calledWithAction.first as! String, action)
        XCTAssertEqual(mock2.calledWithAction.first as! String, action)
    }

    func testCombinedReducerResultsCorrectly() {
        let reducer = combineReducers(multiplyByTwoReducer, increaseByThreeReducer)
        let newState = reducer("action", 3)

        XCTAssertEqual(newState, 9)
    }
}
