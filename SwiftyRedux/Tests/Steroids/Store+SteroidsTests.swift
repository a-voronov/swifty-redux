import XCTest
@testable import SwiftyRedux

private typealias State = Int

private enum AnyAction: Int, Action { case one = 1, two, three, four, five }
private enum OpAction: Action, Equatable { case inc, mul }

class StoreSteroidsTests: XCTestCase {
    func testStore_whenUnsubscribing_stopReceivingStateUpdates() {
        let reducer: Reducer<State> = { action, state in
            (action as! AnyAction).rawValue
        }
        let store = Store<State>(state: 0, reducer: reducer)

        var result: [State] = []
        let disposable = store.subscribe(includingCurrentState: false) { state in
            result.append(state)
        }
        store.dispatch(AnyAction.one)
        store.dispatch(AnyAction.two)
        store.dispatchAndWait(AnyAction.three)

        disposable.dispose()
        store.dispatch(AnyAction.four)
        store.dispatchAndWait(AnyAction.five)

        XCTAssertEqual(result, [1, 2, 3])
    }

    func testStore_whenObserving_andSubscribingToObserver_startReceivingStateUpdates() {
        let reducer: Reducer<State> = { action, state in
            switch action {
            case let action as OpAction where action == .mul: return state * 2
            case let action as OpAction where action == .inc: return state + 3
            default: return state
            }
        }
        let store = Store<State>(state: 3, reducer: reducer)

        var result: [State] = []
        store.stateObservable().subscribe { state in
            result.append(state)
        }
        store.dispatch(OpAction.mul)
        store.dispatchAndWait(OpAction.inc)

        XCTAssertEqual(result, [6, 9])
    }
}
