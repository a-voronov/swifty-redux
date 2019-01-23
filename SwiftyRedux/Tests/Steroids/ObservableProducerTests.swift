import XCTest
@testable import SwiftyRedux

private struct Tuple<T: Equatable, U: Equatable>: Equatable {
    let first: T
    let second: U

    init(_ first: T, _ second: U) {
        self.first = first
        self.second = second
    }
}

private extension Int {
    var string: String {
        return "\(self)"
    }
}

private extension Int {
    var isEven: Bool {
        return self % 2 == 0
    }
}

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

class ObservableProducerExtensionsTests: XCTestCase {
    func testProducer_whenUsingMap_notifiesWithTransformedValues() {
        var result: String!
        let producer = ObservableProducer<Int> { observer, disposables in
            observer.update(42)
        }

        producer.map(String.init).start { value in result = value }

        XCTAssertEqual(result, "42")
    }

    func testProducer_whenUsingFilter_notifiesWithValuesThatPassPredicate() {
        var result = [Int]()
        let producer = ObservableProducer<Int> { observer, disposables in
            observer.update(1)
            observer.update(2)
            observer.update(3)
            observer.update(4)
        }

        producer.filter { $0 % 2 == 0 }.start { value in result.append(value) }

        XCTAssertEqual(result, [2, 4])
    }

    func testProducer_whenUsingFilterMap_notifiesWithTransformedValuesIfTheyPassPredicate() {
        var result = [String]()
        let producer = ObservableProducer<Int> { observer, disposables in
            observer.update(1)
            observer.update(2)
            observer.update(3)
            observer.update(4)
        }

        producer.filterMap { $0 % 2 == 0 ? "\($0)" : nil }.start { value in result.append(value) }

        XCTAssertEqual(result, ["2", "4"])
    }

    func testProducer_whenUsingSkipRepeats_notifiesWithOnlyUniqueValuesAccordingToPredicate() {
        var result = [Int]()
        let producer = ObservableProducer<Int> { observer, disposables in
            observer.update(1)
            observer.update(1)
            observer.update(2)
            observer.update(4)
            observer.update(2)
        }

        producer.skipRepeats { $0 == $1 }.start { value in result.append(value) }

        XCTAssertEqual(result, [1, 2, 4, 2])
    }

    func testProducer_whenUsingSkipFirst_notifiesAfterSpecifiedNumberOfValuesPass() {
        var result = [Int]()
        let producer = ObservableProducer<Int> { observer, disposables in
            observer.update(1)
            observer.update(2)
            observer.update(3)
            observer.update(4)
        }

        producer.skip(first: 2).start { value in result.append(value) }

        XCTAssertEqual(result, [3, 4])
    }

    func testProducer_whenUsingSkipWhile_notifiesWithValuesAfterOneFailsPredicate() {
        var result = [Int]()
        let producer = ObservableProducer<Int> { observer, disposables in
            observer.update(1)
            observer.update(2)
            observer.update(3)
            observer.update(4)
        }

        producer.skip(while: { $0 != 3 }).start { value in result.append(value) }

        XCTAssertEqual(result, [3, 4])
    }

    func testProducer_whenUsingTakeFirst_notifiesWithOnlyFirstNumberOfValues() {
        var result = [Int]()
        let producer = ObservableProducer<Int> { observer, disposables in
            observer.update(1)
            observer.update(2)
            observer.update(3)
            observer.update(4)
        }

        producer.take(first: 2).start { value in result.append(value) }

        XCTAssertEqual(result, [1, 2])
    }

    func testProducer_whenUsingTakeWhile_notifiesWithValuesUntilOneFailsPredicate() {
        var result = [Int]()
        let producer = ObservableProducer<Int> { observer, disposables in
            observer.update(1)
            observer.update(2)
            observer.update(3)
            observer.update(4)
        }

        producer.take(while: { $0 != 3 }).start { value in result.append(value) }

        XCTAssertEqual(result, [1, 2])
    }

    func testProducer_whenUsingCombinePrevious_andInitialValueNotProvided_notifiesOnlyAfterSecondValueWasDispatched() {
        var result = [Tuple<Int, Int>]()
        let producer = ObservableProducer<Int> { observer, disposables in
            observer.update(1)
            observer.update(2)
            observer.update(3)
            observer.update(4)
        }

        producer.combinePrevious().start { value in result.append(.init(value.0, value.1)) }

        XCTAssertEqual(result, [.init(1, 2), .init(2, 3), .init(3, 4)])
    }

    func testProducer_whenUsingCombinePrevious_andInitialValueProvided_notifiesIncludingInitialValueWhileVeryFirstDispatch() {
        var result = [Tuple<Int, Int>]()
        let producer = ObservableProducer<Int> { observer, disposables in
            observer.update(1)
            observer.update(2)
            observer.update(3)
            observer.update(4)
        }

        producer.combinePrevious(initial: 0).start { value in result.append(.init(value.0, value.1)) }

        XCTAssertEqual(result, [.init(0, 1), .init(1, 2), .init(2, 3), .init(3, 4)])
    }

    func testProducer_whenUsingMapWithKeyPath_notifiesWithTransformedValues() {
        var result: String!
        let producer = ObservableProducer<Int> { observer, disposables in
            observer.update(42)
        }

        producer.map(\.string).start { value in result = value }

        XCTAssertEqual(result, "42")
    }

    func testProducer_whenUsingFilterWithKeyPath_notifiesWithValuesThatPassPredicate() {
        var result = [Int]()
        let producer = ObservableProducer<Int> { observer, disposables in
            observer.update(1)
            observer.update(2)
            observer.update(3)
            observer.update(4)
        }

        producer.filter(\.isEven).start { value in result.append(value) }

        XCTAssertEqual(result, [2, 4])
    }
}
