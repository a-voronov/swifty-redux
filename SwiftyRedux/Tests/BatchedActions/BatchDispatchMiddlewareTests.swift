import XCTest
@testable import SwiftyRedux

private typealias State = Int
private enum AnyAction: SwiftyRedux.Action, Equatable {
    case one, two, three, four
}

class BatchDispatchMiddlewareTests: XCTestCase {
    var nextCalledWithAction: [SwiftyRedux.Action]!
    var dispatchCalledWithAction: [SwiftyRedux.Action]!
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
        dispatchMiddleware(BatchAction(AnyAction.one, AnyAction.two))

        XCTAssertEqual(dispatchCalledWithAction as! [AnyAction], [.one, .two])
    }

    func testCallsNextOnlyOnceOnBatchedActions() {
        dispatchMiddleware(BatchAction(AnyAction.one, AnyAction.two))

        XCTAssertEqual(nextCalledWithAction.count, 1)
        XCTAssertTrue(nextCalledWithAction.first is BatchAction)
    }

    func testHandlesNestedBatchedActions() {
        dispatchMiddleware(
            BatchAction(
                AnyAction.one,
                BatchAction(
                    AnyAction.two,
                    AnyAction.three
                ),
                AnyAction.four
            )
        )

        XCTAssertEqual(nextCalledWithAction.count, 1)
        XCTAssertTrue(nextCalledWithAction.first is BatchAction)
        XCTAssertEqual(dispatchCalledWithAction as! [AnyAction], [.one, .two, .three, .four])
    }

    func testCallsNextButNotDispatchForNonBatchedActions() {
        dispatchMiddleware(AnyAction.one)

        XCTAssertEqual(nextCalledWithAction as! [AnyAction], [.one])
        XCTAssertEqual(dispatchCalledWithAction.count, 0)
    }

    func testDispatchesCustomBatchedActions() {
        struct CustomBatchAction: BatchedActions {
            let actions: [Action]
        }

        dispatchMiddleware(CustomBatchAction(actions: [AnyAction.one, AnyAction.two]))

        XCTAssertEqual(nextCalledWithAction.count, 1)
        XCTAssertTrue(nextCalledWithAction.first is CustomBatchAction)
        XCTAssertEqual(dispatchCalledWithAction as! [AnyAction], [.one, .two])
    }
}
