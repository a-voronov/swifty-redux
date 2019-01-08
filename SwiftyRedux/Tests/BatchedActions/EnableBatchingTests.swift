import XCTest
@testable import SwiftyRedux

private typealias State = Int
private struct StringAction: Action, Equatable {
    let value: String
    init(_ value: String) {
        self.value = value
    }
}

private class MockReducer {
    private(set) var calledWithAction: [Action] = []
    private(set) var reducer: Reducer<State>!

    init() {
        reducer = { action, state in
            self.calledWithAction.append(action)
            return state
        }
    }
}

class EnableBatchingTests: XCTestCase {
    private var mock: MockReducer!
    private var batchedReducer: Reducer<State>!

    override func setUp() {
        super.setUp()

        mock = MockReducer()
        batchedReducer = enableBatching(mock.reducer)
    }

    func testNonBatchedActionsArePassedThrough() {
        _ = batchedReducer(StringAction("1"), 0)
        _ = batchedReducer(StringAction("2"), 0)

        XCTAssertEqual(mock.calledWithAction as! [StringAction], [StringAction("1"), StringAction("2")])
    }

    func testEachActionInsideBatchedActionIsPassedThroughSeparately() {
        _ = batchedReducer(BatchAction(StringAction("1"), StringAction("2")), 0)

        XCTAssertEqual(mock.calledWithAction as! [StringAction], [StringAction("1"), StringAction("2")])
    }

    func testEachActionInsideNestedBatchedActionIsPassedThroughSeparatelyInCorrectOrder() {
        _ = batchedReducer(
            BatchAction(
                StringAction("1"),
                BatchAction(
                    BatchAction(
                        StringAction("2"),
                        StringAction("3")
                    ),
                    StringAction("4")
                ),
                StringAction("5")
            ),
        0)

        XCTAssertEqual(
            mock.calledWithAction as! [StringAction],
            [StringAction("1"), StringAction("2"), StringAction("3"), StringAction("4"), StringAction("5")]
        )
    }

    func testCustomBatchedActionsArePassedThrough() {
        struct CustomBatchAction: BatchedActions {
            let actions: [Action]
        }

        _ = batchedReducer(CustomBatchAction(actions: [StringAction("1"), StringAction("2")]), 0)

        XCTAssertEqual(mock.calledWithAction as! [StringAction], [StringAction("1"), StringAction("2")])
    }
}
