import XCTest
@testable import SwiftyRedux

private typealias State = Int

private enum AnyAction: Int, Action { case one = 1, two, three, four, five }
private enum OpAction: Action, Equatable { case inc, mul }

class StoreSteroidsTests: XCTestCase {
    func testSubscribeToStore_whenSkippingRepeats_shouldReceiveUniqueStateUpdates() {
        let actions: [AnyAction] = [.one, .two, .one, .one, .three, .three, .five, .two]
        let reducer: Reducer<State> = { state, action in
            (action as! AnyAction).rawValue
        }
        let store = Store<State>(state: 0, reducer: reducer)

        var result: [State] = []
        store.subscribeUnique(includingCurrentState: false) { state in
            result.append(state)
        }
        actions.forEach(store.dispatchAndWait)

        XCTAssertEqual(result, [1, 2, 1, 3, 5, 2])
    }

    func testSubscribeToStore_whenSkippingRepeats_andIncludingCurrentState_shouldReceiveCurrentStateAndFurtherUniqueStateUpdatesWithoutFirstUpdate() {
        let actions: [AnyAction] = [.one, .two, .one, .one, .three, .three, .five, .two]
        let reducer: Reducer<State> = { state, action in
            (action as! AnyAction).rawValue
        }
        let store = Store<State>(state: 0, reducer: reducer)

        var result: [State] = []
        store.subscribeUnique(includingCurrentState: true) { state in
            result.append(state)
        }
        actions.forEach(store.dispatchAndWait)

        XCTAssertEqual(result, [0, 1, 2, 1, 3, 5, 2])
    }

    func testSubscribeToStore_whenSkippingRepeats_andIncludingCurrentState_andFirstUpdateEqualsToCurrentState_shouldReceiveCurrentStateAndFurtherUniqueStateUpdatesWithoutFirstUpdate() {
        let actions: [AnyAction] = [.one, .two, .one, .one, .three, .three, .five, .two]
        let reducer: Reducer<State> = { state, action in
            (action as! AnyAction).rawValue
        }
        let store = Store<State>(state: 1, reducer: reducer)

        var result: [State] = []
        store.subscribeUnique(includingCurrentState: true) { state in
            result.append(state)
        }
        actions.forEach(store.dispatchAndWait)

        XCTAssertEqual(result, [1, 2, 1, 3, 5, 2])
    }

    func testSubscribeToStore_whenNotSkippingRepeats_shouldReceiveDuplicatedStateUpdates() {
        let actions: [AnyAction] = [.one, .two, .one, .one, .three, .three, .five, .two]
        let reducer: Reducer<State> = { state, action in
            (action as! AnyAction).rawValue
        }
        let store = Store<State>(state: 0, reducer: reducer)

        var result: [State] = []
        store.subscribe(includingCurrentState: false) { state in
            result.append(state)
        }
        actions.forEach(store.dispatchAndWait)

        XCTAssertEqual(result, [1, 2, 1, 1, 3, 3, 5, 2])
    }

    func testStore_whenUnsubscribing_shouldStopReceivingStateUpdates() {
        let reducer: Reducer<State> = { state, action in
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

    func testStore_whenObserving_andSubscribingToObserver_shouldStartReceivingStateUpdates() {
        let reducer: Reducer<State> = { state, action in
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
