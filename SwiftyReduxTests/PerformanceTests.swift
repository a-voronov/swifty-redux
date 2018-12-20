//
//  PerformanceTests.swift
//  SwiftyReduxTests
//
//  Created by Alexander Voronov on 12/20/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

import XCTest
@testable import SwiftyRedux

class PerformanceTests: XCTestCase {
    typealias State = Int

    var observers: [(State) -> Void]!
    var store: Store<State>!

    override func setUp() {
        super.setUp()

        observers = (0..<3000).map { _ in { _ in } }
        store = Store<State>(state: 0, reducer: { action, state in state })
    }

    func testNotify() {
        self.observers.forEach { self.store.subscribe(observer: $0) }
        self.measure {
            self.store.dispatch("action")
            // reading state to wait on a calling thread until writing tasks complete to measure correct time
            let _ = self.store.state
        }
    }

    func testSubscribe() {
        self.measure {
            self.observers.forEach { self.store.subscribe(observer: $0) }
        }
    }
}
