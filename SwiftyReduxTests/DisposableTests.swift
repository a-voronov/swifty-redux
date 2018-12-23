//
//  DisposableTests.swift
//  SwiftyReduxTests
//
//  Created by Alexander Voronov on 12/22/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

import XCTest
@testable import SwiftyRedux

class DisposableTests: XCTestCase {
    func testNopDisposableIsAlreadyDisposed() {
        XCTAssertTrue(Disposable.nop().isDisposed)
    }

    func testActionDisposableIsDisposedOnce() {
        var result = 0
        let disposable = Disposable { result += 1 }

        let exp1 = expectation(description: "first")
        let exp2 = expectation(description: "second")
        let exp3 = expectation(description: "third")
        DispatchQueue.global().async { disposable.dispose(); exp1.fulfill() }
        DispatchQueue.global().async { disposable.dispose(); exp2.fulfill() }
        DispatchQueue.global().async { disposable.dispose(); exp3.fulfill() }

        waitForExpectations(timeout: 0.1) { e in
            XCTAssertEqual(result, 1)
        }
    }

    func testDisposedFlagIsSetNotWaitingForDisposeToFinish() {
        let disposable = Disposable {
            DispatchQueue.global(qos: .background).async { Thread.sleep(forTimeInterval: 0.001) }
        }
        disposable.dispose()
        XCTAssertTrue(disposable.isDisposed)
    }

    func testActionDisposableIsMarkedAsDisposed() {
        var result = false
        let disposable = Disposable { result = true }

        disposable.dispose()

        XCTAssertEqual(result, disposable.isDisposed)
    }

    func testCompositeDisposableDisposesEveryone() {
        var result = 0
        let disposable1 = Disposable { result += 1 }
        let disposable2 = Disposable { result += 1 }
        let disposable3 = Disposable { result += 1 }
        let disposable = CompositeDisposable(disposing: disposable1, disposable2, disposable3)

        disposable.dispose()

        XCTAssertEqual(result, 3)
        XCTAssertTrue(disposable.isDisposed)
    }

    func testCompositeDisposableAddsAlreadyDisposedActions() {
        let disposable = CompositeDisposable()
        weak var nopDisposable: Disposable!

        autoreleasepool {
            let deinitNopDisposable = Disposable.nop()
            nopDisposable = deinitNopDisposable
            disposable.add(nopDisposable)
        }

        XCTAssertNotNil(nopDisposable)
    }
}
