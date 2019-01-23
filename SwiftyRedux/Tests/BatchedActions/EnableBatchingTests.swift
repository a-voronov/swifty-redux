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
        reducer = { state, action in
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
        _ = batchedReducer(0, AnyAction.one)
        _ = batchedReducer(0, AnyAction.two)

        XCTAssertEqual(mock.calledWithAction as! [AnyAction], [.one, .two])
    }

    func testEachActionInsideBatchedActionIsPassedThroughSeparately() {
        _ = batchedReducer(0, BatchAction(AnyAction.one, AnyAction.two))

        XCTAssertEqual(mock.calledWithAction as! [AnyAction], [.one, .two])
    }

    func testEachActionInsideNestedBatchedActionIsPassedThroughSeparatelyInCorrectOrder() {
        _ = batchedReducer(
            0,
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
            )
        )

        XCTAssertEqual(mock.calledWithAction as! [AnyAction], [.one, .two, .three, .four, .five])
    }

    func testCustomBatchedActionsArePassedThrough() {
        struct CustomBatchAction: BatchedActions {
            let actions: [Action]
        }

        _ = batchedReducer(0, CustomBatchAction(actions: [AnyAction.one, AnyAction.two]))

        XCTAssertEqual(mock.calledWithAction as! [AnyAction], [.one, .two])
    }
}
