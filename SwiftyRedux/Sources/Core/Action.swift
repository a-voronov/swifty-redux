//
//  Action.swift
//  SwiftyRedux
//
//  Created by Alexander Voronov on 12/16/18.
//  Copyright © 2018 Alex Voronov. All rights reserved.
//

/// from https://redux.js.org/basics/actions
/// Actions are payloads of information that send data from your application to your store.
/// They are the only source of information for the store.
/// You send them to the store using store.dispatch().

/// All actions that should be dispatched to a store need to conform to this protocol (currentrly without any requirements)
/// Actions should not contain functions. It can be a struct or enum used to express intended state change.
/// You might conform them to `Equatable` or `Codable` protocols for your needs.

public protocol Action {}
