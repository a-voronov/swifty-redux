//
//  Middleware.swift
//  SwiftyRedux
//
//  Created by Alexander Voronov on 12/16/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

public typealias GetState<State> = () -> State
public typealias Dispatch = (Action) -> Void
public typealias Middleware<State> = (@escaping GetState<State>, @escaping Dispatch, @escaping Dispatch) -> Dispatch

public func applyMiddleware<State>(_ middleware: [Middleware<State>]) -> Middleware<State> {
    return { getState, dispatch, next in
        return middleware
            .reversed()
            .reduce(next) { result, current in
                current(getState, dispatch, result)
        }
    }
}

public func createMiddleware<State>(_ sideEffect: @escaping (GetState<State>, Dispatch, Action) -> Void) -> Middleware<State> {
    return { getState, dispatch, next in
        return { action in
            sideEffect(getState, dispatch, action)
            return next(action)
        }
    }
}

public func createMiddleware<State>(_ middleware: @escaping Middleware<State>) -> Middleware<State> {
    return middleware
}
