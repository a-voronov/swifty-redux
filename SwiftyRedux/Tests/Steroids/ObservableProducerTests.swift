import XCTest
@testable import SwiftyRedux

class ObservableProducerTests: XCTestCase {
    func testInitiatorIsNotifiedOfUpdates() {
        var result: Int!
        let producer = ObservableProducer<Int> { observer, disposables in
            observer.update(42)
        }
        producer.start { value in result = value }

        XCTAssertEqual(result, 42)
    }

    func testInitiatorIsNotifiedOnSpecifiedQueueAsynchronously() {
        var result: String!
        let id = "testInitiatorIsNotifiedOnSpecifiedQueueAsynchronously"
        let queueId = DispatchSpecificKey<String>()
        let queue = DispatchQueue(label: id)
        let queueExpectation = expectation(description: id)
        queue.setSpecific(key: queueId, value: id)

        let producer = ObservableProducer<Int> { observer, disposables in
            observer.update(42)
        }

        producer.start(on: queue) { value in
            result = DispatchQueue.getSpecific(key: queueId)
            queueExpectation.fulfill()
        }

        waitForExpectations(timeout: 0.1) { e in
            queue.setSpecific(key: queueId, value: nil)

            XCTAssertEqual(result, id)
        }
    }

    func testInititatorIsNotNotifiedAfterDisposing() {
        var result = [Int]()
        let queue = DispatchQueue(label: "testInititatorIsNotNotifiedAfterDisposing")
        let queueExpectation = expectation(description: queue.label)
        let producer = ObservableProducer<Int> { observer, disposables in
            queue.asyncAfter(deadline: .now() + .milliseconds(5)) {
                (1...5).forEach(observer.update)
                queueExpectation.fulfill()
            }
        }

        var disposable: Disposable!
        disposable = producer.start { value in
            result.append(value)
            if result.count == 3 {
                disposable?.dispose()
            }
        }

        waitForExpectations(timeout: 0.1) { e in
            XCTAssertEqual(result, [1, 2, 3])
        }
    }

    func testInititatorIsNotNotifiedAfterInnerDisposing() {
        var result = [Int]()
        let producer = ObservableProducer<Int> { observer, disposables in
            observer.update(1)
            observer.update(2)
            observer.update(3)
            disposables.dispose()
            observer.update(4)
            observer.update(5)
        }

        producer.start { value in
            result.append(value)
        }
        
        XCTAssertEqual(result, [1, 2, 3])
    }

    func testDisposableIsNotRetainedByAnyoneAtAll() {
        let producer = ObservableProducer<Int> { observer, disposables in }
        weak var disposable = producer.start { value in }

        XCTAssertNil(disposable)
    }

    func testNoInitiatorsAreDisposedWhenProducerDies() {
        var producer: ObservableProducer? = ObservableProducer<Int> { observer, disposables in }
        let disposable1 = producer!.start { value in }
        let disposable2 = producer!.start { value in }
        let disposable3 = producer!.start { value in }

        producer = nil

        XCTAssertFalse([disposable1, disposable2, disposable3].allSatisfy { $0.isDisposed })
    }

    func testProducer_whenInitializedWithValue_shouldUpdateInitiatorsWithOnlyThisValue() {
        let initialValue = 42
        let producer = ObservableProducer<Int>(initialValue)

        producer.start { value in
            XCTAssertEqual(value, initialValue)
        }
    }

    func testProducer_whenInitializedWithAction_shouldUpdateInitiatorsByRunningThisActionEverytime() {
        var variable = 0
        let action: () -> Int = { variable }
        let producer = ObservableProducer<Int>(action)

        variable = 1
        producer.start { value in
            XCTAssertEqual(value, 1)
        }

        variable = 2
        producer.start { value in
            XCTAssertEqual(value, 2)
        }
    }
}
