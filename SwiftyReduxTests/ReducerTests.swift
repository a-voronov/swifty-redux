//
//  ReducerTests.swift
//  SwiftyReduxTests
//
//  Created by Alexander Voronov on 12/16/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

import XCTest
@testable import SwiftyRedux

class ReducerTests: XCTestCase {
    func testCallsReducersOnce() {
        let action = "nop"
        let mock1 = MockReducerContainer()
        let mock2 = MockReducerContainer()
        let reducer = combineReducers(mock1.reducer, mock2.reducer)

        _ = reducer(action, 0)

        XCTAssertEqual(mock1.actions.count, 1)
        XCTAssertEqual(mock2.actions.count, 1)
        XCTAssertEqual(mock1.actions.first as! String, action)
        XCTAssertEqual(mock2.actions.first as! String, action)
    }

    func testCombinesReducerResultsCorrectly() {
        let reducer = combineReducers(increaseByOneReducer, increaseByTwoReducer)
        let newState = reducer("nop", 0)

        XCTAssertEqual(newState, 3)
    }
}

extension String: Action {}

private typealias State = Int

private class MockReducerContainer {
    var actions: [Action] = []
    var reducer: Reducer<State>!

    init() {
        reducer = { action, state in
            self.actions.append(action)
            return state
        }
    }
}

private let increaseByOneReducer: Reducer<State> = { action, state in
    state + 1
}

private let increaseByTwoReducer: Reducer<State> = { action, state in
    state + 2
}
