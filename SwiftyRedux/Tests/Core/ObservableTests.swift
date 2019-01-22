import XCTest
@testable import SwiftyRedux

class ObservableTests: XCTestCase {
    // TODO: test Observable pipe

    func testObserverIsNotifiedOfNewEvents() {
        var result: Int!
        let (observable, observer) = Observable<Int>.pipe()
        observable.subscribe { value in result = value }

        observer.update(42)

        XCTAssertEqual(result, 42)
    }

    func testNewObserverIsNotNotifiedOfOldEvents() {
        var result: Int!
        let (observable, observer) = Observable<Int>.pipe()

        observer.update(0)
        observable.subscribe { value in result = value }
        observer.update(42)

        XCTAssertEqual(result, 42)
    }

    func testObserverIsNotifiedOnSpecifiedQueueAsynchronously() {
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

    func testObserverIsNotNotifiedAfterDisposing() {
        var result = [Int]()
        let (observable, observer) = Observable<Int>.pipe()
        let disposable = observable.subscribe { value in result.append(value) }

        observer.update(0)
        disposable.dispose()
        observer.update(42)

        XCTAssertEqual(result, [0])
    }

    func testDisposableIsNotKeptAfterItDisposes() {
        let observable = Observable<Int> { _ in nil }
        weak var disposable = observable.subscribe { value in }

        XCTAssertNotNil(disposable)
        XCTAssertFalse(disposable!.isDisposed)

        disposable!.dispose()

        XCTAssertNil(disposable)
    }

    func testAllObserversAreDisposedWhenObservableDies() {
        var observable: Observable<Int>? = .init { _ in nil }
        let disposable1 = observable!.subscribe { value in }
        let disposable2 = observable!.subscribe { value in }
        let disposable3 = observable!.subscribe { value in }

        observable = nil

        XCTAssertTrue([disposable1, disposable2, disposable3].allSatisfy { $0.isDisposed })
    }
}
