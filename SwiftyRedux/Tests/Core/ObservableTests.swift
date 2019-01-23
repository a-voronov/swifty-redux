import XCTest
@testable import SwiftyRedux

class ObservableTests: XCTestCase {
    func testSubscriberIsNotifiedOfNewUpdates() {
        var result: Int!
        let (observable, observer) = Observable<Int>.pipe()
        observable.subscribe { value in result = value }

        observer.update(42)

        XCTAssertEqual(result, 42)
    }

    func testNewSubscriberIsNotNotifiedOfOldUpdates() {
        var result: Int!
        let (observable, observer) = Observable<Int>.pipe()

        observer.update(0)
        observable.subscribe { value in result = value }
        observer.update(42)

        XCTAssertEqual(result, 42)
    }

    func testSubscriberIsNotifiedOnSpecifiedQueueAsynchronously() {
        let id = "testObserverIsNotifiedOnSpecifiedQueueAsynchronously"
        let queueId = DispatchSpecificKey<String>()
        let queue = DispatchQueue(label: id)
        queue.setSpecific(key: queueId, value: id)

        var result: String!
        let (observable, observer) = Observable<Int>.pipe(queue: queue)
        let queueExpectation = expectation(description: id)

        observable.subscribe { value in
            result = DispatchQueue.getSpecific(key: queueId)
            queueExpectation.fulfill()
        }

        observer.update(42)

        waitForExpectations(timeout: 0.1) { e in
            queue.setSpecific(key: queueId, value: nil)

            XCTAssertEqual(result, id)
        }
    }

    func testSubscriberIsNotNotifiedAfterDisposing() {
        var result = [Int]()
        let (observable, observer) = Observable<Int>.pipe()
        let disposable = observable.subscribe { value in result.append(value) }

        observer.update(0)
        disposable.dispose()
        observer.update(42)

        XCTAssertEqual(result, [0])
    }

    func testDisposableIsNotRetainedAfterItDisposes() {
        let observable = Observable<Int> { _ in nil }
        weak var disposable = observable.subscribe { value in }

        XCTAssertNotNil(disposable)
        XCTAssertFalse(disposable!.isDisposed)

        disposable!.dispose()

        XCTAssertNil(disposable)
    }

    func testAllSubscribersAreDisposedWhenObservableDies() {
        var observable: Observable<Int>? = .init { _ in nil }
        let disposable1 = observable!.subscribe { value in }
        let disposable2 = observable!.subscribe { value in }
        let disposable3 = observable!.subscribe { value in }

        observable = nil

        XCTAssertTrue([disposable1, disposable2, disposable3].allSatisfy { $0.isDisposed })
    }

    func testPipe_whenSpecifyingObserverQueue_andSubscribingToObservableWithDifferentQueue_shouldNotifySubscribersOnSubscribingQueue() {
        let id = "testPipe_whenSpecifyingObserverQueue_andSubscribingToObservableWithDifferentQueue_shouldNotifySubscribersOnSubscribingQueue"

        let observerQueueId = DispatchSpecificKey<String>()
        let observerQueue = DispatchQueue(label: id + "observer")
        observerQueue.setSpecific(key: observerQueueId, value: observerQueue.label)

        let subscribersQueueId = DispatchSpecificKey<String>()
        let subscribersQueue = DispatchQueue(label: id + "subscribers")
        subscribersQueue.setSpecific(key: subscribersQueueId, value: subscribersQueue.label)

        var result: String!
        let (observable, observer) = Observable<Int>.pipe(queue: observerQueue)
        let queueExpectation = expectation(description: id)

        observable.subscribe(on: subscribersQueue) { value in
            result = DispatchQueue.getSpecific(key: subscribersQueueId)
            queueExpectation.fulfill()
        }

        observer.update(42)

        waitForExpectations(timeout: 0.1) { e in
            observerQueue.setSpecific(key: observerQueueId, value: nil)
            subscribersQueue.setSpecific(key: subscribersQueueId, value: nil)

            XCTAssertEqual(result, subscribersQueue.label)
        }
    }

    func testObservable_whenInitializedWithAnotherObservable_shouldSubscribeToItsUpdates() {
        var result = [Int]()
        let (sourceObservable, sourceObserver) = Observable<Int>.pipe()
        let observable = Observable<Int>(observable: sourceObservable)

        observable.subscribe { value in
            result.append(value)
        }

        sourceObserver.update(1)
        sourceObserver.update(2)
        sourceObserver.update(3)

        XCTAssertEqual(result, [1, 2, 3])
    }

    func testObservable_whenInitializedWithAnotherObservable_shouldStopReceivingUpdatesAfterDisposing() {
        var result = [Int]()
        let (sourceObservable, sourceObserver) = Observable<Int>.pipe()
        let observable = Observable(observable: sourceObservable)
        let disposable = observable.subscribe { value in
            result.append(value)
        }

        sourceObserver.update(1)
        sourceObserver.update(2)
        disposable.dispose()
        sourceObserver.update(3)

        XCTAssertEqual(result, [1, 2])
    }
}
