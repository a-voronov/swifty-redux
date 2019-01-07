import XCTest
@testable import SwiftyRedux

private typealias State = Int

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
        _ = batchedReducer("action1", 0)
        _ = batchedReducer("action2", 0)

        XCTAssertEqual(mock.calledWithAction as! [String], ["action1", "action2"])
    }

    func testEachActionInsideBatchedActionIsPassedThroughSeparately() {
        _ = batchedReducer(BatchAction("action1", "action2"), 0)

        XCTAssertEqual(mock.calledWithAction as! [String], ["action1", "action2"])
    }

    func testEachActionInsideNestedBatchedActionIsPassedThroughSeparatelyInCorrectOrder() {
        _ = batchedReducer(BatchAction("action1", BatchAction(BatchAction("action2", "action3"), "action4"), "action5"), 0)

        XCTAssertEqual(mock.calledWithAction as! [String], ["action1", "action2", "action3", "action4", "action5"])
    }

    func testCustomBatchedActionsArePassedThrough() {
        struct CustomBatchAction: BatchedActions {
            let actions: [Action]
        }

        _ = batchedReducer(CustomBatchAction(actions: ["action1", "action2"]), 0)

        XCTAssertEqual(mock.calledWithAction as! [String], ["action1", "action2"])
    }
}
