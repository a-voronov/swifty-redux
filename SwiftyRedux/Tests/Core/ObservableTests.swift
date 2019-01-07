import XCTest
@testable import SwiftyRedux

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

    func testObserverIsNotNotifiedAfterDisposing() {
        var result = [Int]()
        let (notify, observable): ObservablePipe<Int> = pipe()
        let disposable = observable.subscribe { value in result.append(value) }

        notify(0)
        disposable.dispose()
        notify(42)

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

    func testObservable_whenUsingMap_notifiesWithTransformedValues() {
        var result: String!
        let (notify, observable): ObservablePipe<Int> = pipe()
        observable.map(String.init).subscribe { value in result = value }

        notify(42)

        XCTAssertEqual(result, "42")
    }

    func testObservable_whenUsingFilter_notifiesWithValuesThatPassPredicate() {
        var result = [Int]()
        let (notify, observable): ObservablePipe<Int> = pipe()
        observable.filter { $0 % 2 == 0 }.subscribe { value in result.append(value) }

        notify(1)
        notify(2)
        notify(3)
        notify(4)

        XCTAssertEqual(result, [2, 4])
    }

    func testObservable_whenUsingFilterMap_notifiesWithTransformedValuesIfTheyPassPredicate() {
        var result = [String]()
        let (notify, observable): ObservablePipe<Int> = pipe()
        observable.filterMap { $0 % 2 == 0 ? "\($0)" : nil }.subscribe { value in result.append(value) }

        notify(1)
        notify(2)
        notify(3)
        notify(4)

        XCTAssertEqual(result, ["2", "4"])
    }

    func testObservable_whenUsingSkipRepeats_notifiesWithOnlyUniqueValuesAccordingToPredicate() {
        var result = [Int]()
        let (notify, observable): ObservablePipe<Int> = pipe()
        observable.skipRepeats { $0 == $1 }.subscribe { value in result.append(value) }

        notify(1)
        notify(1)
        notify(2)
        notify(4)
        notify(2)

        XCTAssertEqual(result, [1, 2, 4, 2])
    }

    func testObservable_whenUsingSkipFirst_notifiesAfterSpecifiedNumberOfValuesPass() {
        var result = [Int]()
        let (notify, observable): ObservablePipe<Int> = pipe()
        observable.skip(first: 2).subscribe { value in result.append(value) }

        notify(1)
        notify(2)
        notify(3)
        notify(4)

        XCTAssertEqual(result, [3, 4])
    }

    func testObservable_whenUsingSkipWhile_notifiesWithValuesAfterOneFailsPredicate() {
        var result = [Int]()
        let (notify, observable): ObservablePipe<Int> = pipe()
        observable.skip(while: { $0 != 3 }).subscribe { value in result.append(value) }

        notify(1)
        notify(2)
        notify(3)
        notify(4)

        XCTAssertEqual(result, [3, 4])
    }

    func testObservable_whenUsingTakeFirst_notifiesWithOnlyFirstNumberOfValues() {
        var result = [Int]()
        let (notify, observable): ObservablePipe<Int> = pipe()
        observable.take(first: 2).subscribe { value in result.append(value) }

        notify(1)
        notify(2)
        notify(3)
        notify(4)

        XCTAssertEqual(result, [1, 2])
    }

    func testObservable_whenUsingTakeWhile_notifiesWithValuesUntilOneFailsPredicate() {
        var result = [Int]()
        let (notify, observable): ObservablePipe<Int> = pipe()
        observable.take(while: { $0 != 3 }).subscribe { value in result.append(value) }

        notify(1)
        notify(2)
        notify(3)
        notify(4)

        XCTAssertEqual(result, [1, 2])
    }

    func testObservable_whenUsingCombinePrevious_andInitialValueNotProvided_notifiesOnlyAfterSecondValueWasDispatched() {
        var result = [Tuple<Int, Int>]()
        let (notify, observable): ObservablePipe<Int> = pipe()
        observable.combinePrevious().subscribe { value in result.append(.init(value.0, value.1)) }

        notify(1)
        notify(2)
        notify(3)
        notify(4)

        XCTAssertEqual(result, [.init(1, 2), .init(2, 3), .init(3, 4)])
    }

    func testObservable_whenUsingCombinePrevious_andInitialValueProvided_notifiesIncludingInitialValueWhileVeryFirstDispatch() {
        var result = [Tuple<Int, Int>]()
        let (notify, observable): ObservablePipe<Int> = pipe()
        observable.combinePrevious(initial: 0).subscribe { value in result.append(.init(value.0, value.1)) }

        notify(1)
        notify(2)
        notify(3)
        notify(4)

        XCTAssertEqual(result, [.init(0, 1), .init(1, 2), .init(2, 3), .init(3, 4)])
    }

    func testObservable_whenUsingMapWithKeyPath_notifiesWithTransformedValues() {
        var result: String!
        let (notify, observable): ObservablePipe<Int> = pipe()
        observable.map(\.string).subscribe { value in result = value }

        notify(42)

        XCTAssertEqual(result, "42")
    }

    func testObservable_whenUsingFilterWithKeyPath_notifiesWithValuesThatPassPredicate() {
        var result = [Int]()
        let (notify, observable): ObservablePipe<Int> = pipe()
        observable.filter(\.isEven).subscribe { value in result.append(value) }

        notify(1)
        notify(2)
        notify(3)
        notify(4)

        XCTAssertEqual(result, [2, 4])
    }
}

private typealias ObservablePipe<T> = (input: (T) -> Void, output: Observable<T>)
private func pipe<T>(queue: DispatchQueue? = nil, disposable: Disposable? = nil) -> ObservablePipe<T> {
    var input: ((T) -> Void)!
    let output = Observable<T> { updates in
        input = Observer(queue: queue, update: updates).update
        return disposable
    }
    return (input, output)
}

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
