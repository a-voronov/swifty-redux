/*:
 > # IMPORTANT: To use `SwiftyRedux.playground`, please:

 1. Open `SwiftyRedux.xcworkspace`
 1. Build `SwiftyRedux-Example` scheme
 1. Finally open the `SwiftyRedux.playground`
 1. Choose `View > Show Debug Area`
 */

import Foundation
import PlaygroundSupport
import SwiftyRedux

struct MainState {
    var isRunning: Bool
}

let mainReducer: Reducer<MainState> = { state, action in
    return state
}

let strore = Store(state: MainState(isRunning: true), reducer: mainReducer)
