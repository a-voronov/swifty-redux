import XCTest
@testable import SwiftyRedux

private typealias State = Int
private struct StringAction: Action, Equatable {
    let value: String
    init(_ value: String) {
        self.value = value
    }
}

class BatchDispatchMiddlewareTests: XCTestCase {
    var nextCalledWithAction: [Action]!
    var dispatchCalledWithAction: [Action]!
    var dispatchMiddleware: Dispatch!

    override func setUp() {
        super.setUp()

        let middleware: Middleware<State> = batchDispatchMiddleware()
        nextCalledWithAction = []
        dispatchCalledWithAction = []
        dispatchMiddleware = middleware(
            { 0 },
            { action in self.dispatchCalledWithAction.append(action) },
            { action in self.nextCalledWithAction.append(action) }
        )
    }

    func testDispatchesAllBatchedActions() {
        dispatchMiddleware(BatchAction(StringAction("1"), StringAction("2")))

        XCTAssertEqual(dispatchCalledWithAction as! [StringAction], [StringAction("1"), StringAction("2")])
    }

    func testCallsNextOnlyOnceOnBatchedActions() {
        dispatchMiddleware(BatchAction(StringAction("1"), StringAction("2")))

        XCTAssertEqual(nextCalledWithAction.count, 1)
        XCTAssertTrue(nextCalledWithAction.first is BatchAction)
    }

    func testHandlesNestedBatchedActions() {
        dispatchMiddleware(
            BatchAction(
                StringAction("1"),
                BatchAction(
                    StringAction("2"),
                    StringAction("3")
                ),
                StringAction("4")
            )
        )

        XCTAssertEqual(nextCalledWithAction.count, 1)
        XCTAssertTrue(nextCalledWithAction.first is BatchAction)
        XCTAssertEqual(dispatchCalledWithAction as! [StringAction], [StringAction("1"), StringAction("2"), StringAction("3"), StringAction("4")])
    }

    func testCallsNextButNotDispatchForNonBatchedActions() {
        dispatchMiddleware(StringAction("action"))

        XCTAssertEqual(nextCalledWithAction as! [StringAction], [StringAction("action")])
        XCTAssertEqual(dispatchCalledWithAction.count, 0)
    }

    func testDispatchesCustomBatchedActions() {
        struct CustomBatchAction: BatchedActions {
            let actions: [Action]
        }

        dispatchMiddleware(CustomBatchAction(actions: [StringAction("1"), StringAction("2")]))

        XCTAssertEqual(nextCalledWithAction.count, 1)
        XCTAssertTrue(nextCalledWithAction.first is CustomBatchAction)
        XCTAssertEqual(dispatchCalledWithAction as! [StringAction], [StringAction("1"), StringAction("2")])
    }
}
