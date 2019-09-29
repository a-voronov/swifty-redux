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
        var state = 0
        batchedReducer(&state, AnyAction.one)
        batchedReducer(&state, AnyAction.two)

        XCTAssertEqual(mock.calledWithAction as! [AnyAction], [.one, .two])
    }

    func testEachActionInsideBatchedActionIsPassedThroughSeparately() {
        var state = 0
        batchedReducer(&state, BatchAction(AnyAction.one, AnyAction.two))

        XCTAssertEqual(mock.calledWithAction as! [AnyAction], [.one, .two])
    }

    func testEachActionInsideNestedBatchedActionIsPassedThroughSeparatelyInCorrectOrder() {
        var state = 0
        batchedReducer(
            &state,
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
        var state = 0
        batchedReducer(&state, CustomBatchAction(actions: [AnyAction.one, AnyAction.two]))

        XCTAssertEqual(mock.calledWithAction as! [AnyAction], [.one, .two])
    }
}
