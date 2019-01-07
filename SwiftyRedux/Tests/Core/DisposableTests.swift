import XCTest
@testable import SwiftyRedux

class DisposableTests: XCTestCase {
    func testNopDisposableIsAlreadyDisposed() {
        XCTAssertTrue(Disposable.nop().isDisposed)
    }

    func testDisposableIsDisposedOnce() {
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

    func testDisposable_whenDisposing_disposableIsMarkedAsDisposed() {
        var result = false
        let disposable = Disposable { result = true }

        disposable.dispose()

        XCTAssertEqual(result, disposable.isDisposed)
    }

    func testDisposable_whenDisposing_isDisposedFlagSetNotWaitingForDisposeToFinish() {
        let disposable = Disposable {
            DispatchQueue.global(qos: .background).async { Thread.sleep(forTimeInterval: 0.001) }
        }

        disposable.dispose()

        XCTAssertTrue(disposable.isDisposed)
    }

    func testCompositeDisposableDisposesAllAddedDisposables() {
        var result = 0
        let disposable1 = Disposable { result += 1 }
        let disposable2 = Disposable { result += 1 }
        let disposable3 = Disposable { result += 1 }
        let disposables = CompositeDisposable(disposing: disposable1, disposable2, disposable3)

        disposables.dispose()

        XCTAssertEqual(result, 3)
        XCTAssertTrue(disposables.isDisposed)
    }

    func testCompositeDisposableAddsAlreadyDisposedDisposable() {
        let disposables = CompositeDisposable()
        weak var nopDisposable: Disposable!

        autoreleasepool {
            let deinitNopDisposable = Disposable.nop()
            nopDisposable = deinitNopDisposable
            disposables.add(nopDisposable)
        }

        XCTAssertNotNil(nopDisposable)
    }

    func testCompositeDisposableAddsAlreadyDisposedDisposables() {
        let disposables = CompositeDisposable()
        weak var nopDisposable1: Disposable!
        weak var nopDisposable2: Disposable!
        weak var nopDisposable3: Disposable!

        autoreleasepool {
            let deinitNopDisposable1 = Disposable.nop()
            let deinitNopDisposable2 = Disposable.nop()
            let deinitNopDisposable3 = Disposable.nop()
            nopDisposable1 = deinitNopDisposable1
            nopDisposable2 = deinitNopDisposable2
            nopDisposable3 = deinitNopDisposable3
            disposables.add([nopDisposable1, nopDisposable2, nopDisposable3])
        }

        XCTAssertNotNil(nopDisposable1)
        XCTAssertNotNil(nopDisposable2)
        XCTAssertNotNil(nopDisposable3)
    }

    func testCompositeDisposable_ifAlreadyDisposed_whenAddingDisposable_immediatelyDisposesIt() {
        let disposables = CompositeDisposable()
        let disposable = Disposable { }

        disposables.dispose()

        XCTAssertTrue(disposables.isDisposed)
        XCTAssertFalse(disposable.isDisposed)

        disposables.add(disposable)

        XCTAssertTrue(disposable.isDisposed)
    }

    func testCompositeDisposable_ifAlreadyDisposed_whenAddingMultipleDisposables_immediatelyDisposesThem() {
        let disposables = CompositeDisposable()
        let disposable1 = Disposable { }
        let disposable2 = Disposable { }
        let disposable3 = Disposable { }

        disposables.dispose()

        XCTAssertTrue(disposables.isDisposed)
        XCTAssertFalse([disposable1, disposable2, disposable3].allSatisfy { $0.isDisposed })

        disposables.add([disposable1, disposable2, disposable3])

        XCTAssertTrue([disposable1, disposable2, disposable3].allSatisfy { $0.isDisposed })
    }

    func testCompositeDisposable_whenAddingAction_returnsDisposableCreatedWithIt() {
        var result = false
        let disposables = CompositeDisposable()
        let disposable = disposables += { result = true }

        disposable.dispose()

        XCTAssertTrue(result)
    }
}
