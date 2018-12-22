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
        XCTAssertTrue(NopDisposable().isDisposed)
    }

    func testActionDisposableIsDisposedOnce() {
        var result = 0
        let disposable = ActionDisposable { result += 1 }

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
        let disposable = ActionDisposable {
            DispatchQueue.global(qos: .background).async { Thread.sleep(forTimeInterval: 0.001) }
        }
        disposable.dispose()
        XCTAssertTrue(disposable.isDisposed)
    }

    func testActionDisposableIsMarkedAsDisposed() {
        var result = false
        let disposable = ActionDisposable { result = true }

        disposable.dispose()

        XCTAssertEqual(result, disposable.isDisposed)
    }

    func testDisposeBagDisposesEveryoneWhenDies() {
        var result = 0
        let disposable1 = ActionDisposable { result += 1 }
        let disposable2 = ActionDisposable { result += 1 }
        let disposable3 = ActionDisposable { result += 1 }

        _ = DisposeBag(disposing: disposable1, disposable2, disposable3)

        XCTAssertEqual(result, 3)
    }

    func testDisposeBagAddsAlreadyDisposedActions() {
        let disposeBag = DisposeBag()
        weak var nopDisposable: NopDisposable!

        autoreleasepool {
            let deinitNopDisposable = NopDisposable()
            nopDisposable = deinitNopDisposable
            disposeBag.add(nopDisposable)
        }

        XCTAssertNotNil(nopDisposable)
    }
}
