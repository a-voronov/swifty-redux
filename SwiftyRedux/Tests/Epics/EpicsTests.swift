import XCTest
import ReactiveSwift

@testable import SwiftyRedux

private typealias State = Int
private enum AnyAction: SwiftyRedux.Action, Equatable {
    case one, two, three
}

private class MockEpic {
    private(set) var calledSetupCount: Int = 0
    private(set) var calledWithAction: [SwiftyRedux.Action] = []
    private(set) var epic: Epic<State>!

    init() {
        epic = { actions, state in
            self.calledSetupCount += 1
            return actions.on(value: { action in
                self.calledWithAction.append(action)
            })
        }
    }
}

class EpicsTests: XCTestCase {
    func testCombineEpicsCallsEachEpicOnce() {
        
    }

    func testEpicMiddlewareCanGetState() {

    }

    func testEpicMiddlewareCanDispatch() {

    }

    func testEpicMiddlewareStoreCallbackIsCalledOnce() {

    }

    func testEpicMiddlewareNextIsCalledBeforeEpic() {

    }
}
