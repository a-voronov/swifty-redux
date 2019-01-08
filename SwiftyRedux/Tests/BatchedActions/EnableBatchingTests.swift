import XCTest
@testable import SwiftyRedux

private typealias State = Int
private enum AnyAction: Action, Equatable {
    case one, two, three, four, five
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
        _ = batchedReducer(AnyAction.one, 0)
        _ = batchedReducer(AnyAction.two, 0)

        XCTAssertEqual(mock.calledWithAction as! [AnyAction], [.one, .two])
    }

    func testEachActionInsideBatchedActionIsPassedThroughSeparately() {
        _ = batchedReducer(BatchAction(AnyAction.one, AnyAction.two), 0)

        XCTAssertEqual(mock.calledWithAction as! [AnyAction], [.one, .two])
    }

    func testEachActionInsideNestedBatchedActionIsPassedThroughSeparatelyInCorrectOrder() {
        _ = batchedReducer(
            BatchAction(
                AnyAction.one,
                BatchAction(
                    BatchAction(
                        AnyAction.two,
                        AnyAction.three
                    ),
                    AnyAction.four
                ),
                AnyAction.five
            ),
        0)

        XCTAssertEqual(mock.calledWithAction as! [AnyAction], [.one, .two, .three, .four, .five])
    }

    func testCustomBatchedActionsArePassedThrough() {
        struct CustomBatchAction: BatchedActions {
            let actions: [Action]
        }

        _ = batchedReducer(CustomBatchAction(actions: [AnyAction.one, AnyAction.two]), 0)

        XCTAssertEqual(mock.calledWithAction as! [AnyAction], [.one, .two])
    }
}
