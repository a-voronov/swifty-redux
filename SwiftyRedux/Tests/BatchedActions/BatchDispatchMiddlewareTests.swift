import XCTest
@testable import SwiftyRedux

private typealias State = Int
private typealias StringAction = String

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
        dispatchMiddleware(BatchAction("action1", "action2"))

        XCTAssertEqual(dispatchCalledWithAction as! [StringAction], ["action1", "action2"])
    }

    func testCallsNextOnlyOnceOnBatchedActions() {
        dispatchMiddleware(BatchAction("action1", "action2"))

        XCTAssertEqual(nextCalledWithAction.count, 1)
        XCTAssertTrue(nextCalledWithAction.first is BatchAction)
    }

    func testHandlesNestedBatchedActions() {
        dispatchMiddleware(BatchAction("action1", BatchAction("action2", "action3"), "action4"))

        XCTAssertEqual(nextCalledWithAction.count, 1)
        XCTAssertTrue(nextCalledWithAction.first is BatchAction)
        XCTAssertEqual(dispatchCalledWithAction as! [StringAction], ["action1", "action2", "action3", "action4"])
    }

    func testCallsNextButNotDispatchForNonBatchedActions() {
        dispatchMiddleware("action")

        XCTAssertEqual(nextCalledWithAction as! [StringAction], ["action"])
        XCTAssertEqual(dispatchCalledWithAction.count, 0)
    }

    func testDispatchesCustomBatchedActions() {
        struct CustomBatchAction: BatchedActions {
            let actions: [Action]
        }

        dispatchMiddleware(CustomBatchAction(actions: ["action1", "action2"]))

        XCTAssertEqual(nextCalledWithAction.count, 1)
        XCTAssertTrue(nextCalledWithAction.first is CustomBatchAction)
        XCTAssertEqual(dispatchCalledWithAction as! [StringAction], ["action1", "action2"])
    }
}
