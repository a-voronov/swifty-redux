//
//  ObservableTests.swift
//  SwiftyReduxTests
//
//  Created by Alexander Voronov on 12/23/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

import XCTest
@testable import SwiftyRedux

private typealias ObservablePipe<T> = (input: (T) -> Void, output: Observable<T>)
private func pipe<T>(queue: DispatchQueue? = nil, disposable: Disposable? = nil) -> ObservablePipe<T> {
    var input: ((T) -> Void)!
    let output = Observable<T> { updates in
        input = Observer(queue: queue, update: updates).update
        return disposable ?? .nop()
    }
    return (input, output)
}

class ObservableTests: XCTestCase {
    func testObserverIsNotifiedOfNewEvents() {
        var result: Int!
        let (notify, observable): ObservablePipe<Int> = pipe()
        observable.subscribe { value in result = value }

        notify(42)

        XCTAssertEqual(result, 42)
    }

    func testNewObserverIsNotNotifiedOfOldEvents() {
        var result: Int!
        let (notify, observable): ObservablePipe<Int> = pipe()

        notify(0)
        observable.subscribe { value in result = value }
        notify(42)

        XCTAssertEqual(result, 42)
    }

    func testObserverIsNotifiedOnSpecifiedQueueAsynchronously() {
        let id = "testObserverIsNotifiedOnSpecifiedQueueAsynchronously"
        let queueId = DispatchSpecificKey<String>()
        let queue = DispatchQueue(label: id)
        queue.setSpecific(key: queueId, value: id)

        var result: String!
        let (notify, observable): ObservablePipe<Int> = pipe(queue: queue)
        let queueExpectation = expectation(description: id)

        observable.subscribe { value in
            result = DispatchQueue.getSpecific(key: queueId)
            queueExpectation.fulfill()
        }

        notify(42)

        XCTAssertNil(result)

        waitForExpectations(timeout: 0.1) { e in
            queue.setSpecific(key: queueId, value: nil)

            XCTAssertEqual(result, id)
        }
    }

//    func testObserverIsNotNotifiedAfterDisposing() {
//        var result: Int!
//        let disposable = Disposable {
//
//        }
//        let (notify, observable): ObservablePipe<Int> = pipe()
//        observable.subscribe { value in result = value }
//
//        notify(42)
//
//        XCTAssertEqual(result, 42)
//    }

    func testAllObserversAreDisposedWhenObservableDies() {

    }

    func testNotifiesWithTransforemedValuesUsingMap() {

    }

    func testNotNotifiesWithValuesNotPassingPredicateUsingFilter() {

    }

    func testNotifiesWithOnlyUniqueValuesAccordingToPredicateUsingSkipRepeat() {

    }

    func testNotNotifiesWithFirstNumberOfValuesUsingSkipFirst() {

    }

    func testNotNotifiesWithValuesUntilOneFailsPredicateUsingSkipWhile() {

    }

    func testNotifiesOnlyWithFirstNumberOfValuesUsingTakeFirst() {

    }

    func testNotifiesWithValuesUntilPredicateFailsUsingTakeWhile() {

    }

    func testNotifiesWithBothPreviousAndCurrentValueAfterSecondValueWasDispatchedIfNoInitialValueProvidedUsingCombinePrevious() {

    }

    func testNotifiesWithBothPreviousAndCurrentValueIncludingInitialValueWhileFirstEventIfItWasProvidedUsingCombinePrevious() {

    }
}
