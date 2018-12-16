//
//  Reducer.swift
//  SwiftyRedux
//
//  Created by Alexander Voronov on 12/16/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

public typealias Reducer<State> = (_ action: Action, _ state: State) -> State

public func combineReducers<State>(_ first: @escaping Reducer<State>, _ rest: Reducer<State>...) -> Reducer<State> {
    return { action, state in
        rest.reduce(first(action, state)) { state, reducer in
            reducer(action, state)
        }
    }
}
