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

class ObservableSteroidsTests: XCTestCase {
    func testObservable_whenUsingMap_notifiesWithTransformedValues() {
        var result: String!
        let (observable, observer) = Observable<Int>.pipe()
        observable.map(String.init).subscribe { value in result = value }

        observer.update(42)

        XCTAssertEqual(result, "42")
    }

    func testObservable_whenUsingFilter_notifiesWithValuesThatPassPredicate() {
        var result = [Int]()
        let (observable, observer) = Observable<Int>.pipe()
        observable.filter { $0 % 2 == 0 }.subscribe { value in result.append(value) }

        observer.update(1)
        observer.update(2)
        observer.update(3)
        observer.update(4)

        XCTAssertEqual(result, [2, 4])
    }

    func testObservable_whenUsingFilterMap_notifiesWithTransformedValuesIfTheyPassPredicate() {
        var result = [String]()
        let (observable, observer) = Observable<Int>.pipe()
        observable.filterMap { $0 % 2 == 0 ? "\($0)" : nil }.subscribe { value in result.append(value) }

        observer.update(1)
        observer.update(2)
        observer.update(3)
        observer.update(4)

        XCTAssertEqual(result, ["2", "4"])
    }

    func testObservable_whenUsingSkipRepeats_notifiesWithOnlyUniqueValuesAccordingToPredicate() {
        var result = [Int]()
        let (observable, observer) = Observable<Int>.pipe()
        observable.skipRepeats { $0 == $1 }.subscribe { value in result.append(value) }

        observer.update(1)
        observer.update(1)
        observer.update(2)
        observer.update(4)
        observer.update(2)

        XCTAssertEqual(result, [1, 2, 4, 2])
    }

    func testObservable_whenUsingSkipFirst_notifiesAfterSpecifiedNumberOfValuesPass() {
        var result = [Int]()
        let (observable, observer) = Observable<Int>.pipe()
        observable.skip(first: 2).subscribe { value in result.append(value) }

        observer.update(1)
        observer.update(2)
        observer.update(3)
        observer.update(4)

        XCTAssertEqual(result, [3, 4])
    }

    func testObservable_whenUsingSkipWhile_notifiesWithValuesAfterOneFailsPredicate() {
        var result = [Int]()
        let (observable, observer) = Observable<Int>.pipe()
        observable.skip(while: { $0 != 3 }).subscribe { value in result.append(value) }

        observer.update(1)
        observer.update(2)
        observer.update(3)
        observer.update(4)

        XCTAssertEqual(result, [3, 4])
    }

    func testObservable_whenUsingTakeFirst_notifiesWithOnlyFirstNumberOfValues() {
        var result = [Int]()
        let (observable, observer) = Observable<Int>.pipe()
        observable.take(first: 2).subscribe { value in result.append(value) }

        observer.update(1)
        observer.update(2)
        observer.update(3)
        observer.update(4)

        XCTAssertEqual(result, [1, 2])
    }

    func testObservable_whenUsingTakeWhile_notifiesWithValuesUntilOneFailsPredicate() {
        var result = [Int]()
        let (observable, observer) = Observable<Int>.pipe()
        observable.take(while: { $0 != 3 }).subscribe { value in result.append(value) }

        observer.update(1)
        observer.update(2)
        observer.update(3)
        observer.update(4)

        XCTAssertEqual(result, [1, 2])
    }

    func testObservable_whenUsingCombinePrevious_andInitialValueNotProvided_notifiesOnlyAfterSecondValueWasDispatched() {
        var result = [Tuple<Int, Int>]()
        let (observable, observer) = Observable<Int>.pipe()
        observable.combinePrevious().subscribe { value in result.append(.init(value.0, value.1)) }

        observer.update(1)
        observer.update(2)
        observer.update(3)
        observer.update(4)

        XCTAssertEqual(result, [.init(1, 2), .init(2, 3), .init(3, 4)])
    }

    func testObservable_whenUsingCombinePrevious_andInitialValueProvided_notifiesIncludingInitialValueWhileVeryFirstDispatch() {
        var result = [Tuple<Int, Int>]()
        let (observable, observer) = Observable<Int>.pipe()
        observable.combinePrevious(initial: 0).subscribe { value in result.append(.init(value.0, value.1)) }

        observer.update(1)
        observer.update(2)
        observer.update(3)
        observer.update(4)

        XCTAssertEqual(result, [.init(0, 1), .init(1, 2), .init(2, 3), .init(3, 4)])
    }

    func testObservable_whenUsingMapWithKeyPath_notifiesWithTransformedValues() {
        var result: String!
        let (observable, observer) = Observable<Int>.pipe()
        observable.map(\.string).subscribe { value in result = value }

        observer.update(42)

        XCTAssertEqual(result, "42")
    }

    func testObservable_whenUsingFilterWithKeyPath_notifiesWithValuesThatPassPredicate() {
        var result = [Int]()
        let (observable, observer) = Observable<Int>.pipe()
        observable.filter(\.isEven).subscribe { value in result.append(value) }

        observer.update(1)
        observer.update(2)
        observer.update(3)
        observer.update(4)

        XCTAssertEqual(result, [2, 4])
    }
}
