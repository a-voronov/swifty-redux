# swifty-redux [![Build Status](https://travis-ci.com/a-voronov/swifty-redux.svg?branch=master)](https://travis-ci.com/a-voronov/swifty-redux)

Swifty implementation of [Redux](https://redux.js.org)

---

![redux](redux.jpg)

## Redux components

### [State](https://redux.js.org/introduction/core-concepts)
* Data structure
* Consists of domain states

### [Action](https://redux.js.org/basics/actions)
* Data structure
* We’re interested in its type

### [Store](https://redux.js.org/basics/store)
* Stores state
* Handles actions dispatching through serial queue
* Propagates action through middleware to reducers and receives it back (synchronously)
* Notifies observers of state changes

### [Middleware](https://redux.js.org/advanced/advanced-tutorial)
* Handles actions for any async/side-effect tasks
* Dispatches actions through `dispatch`
* Decorates over other middleware, but doesn’t know anything about any of them - i.e. (m(m(m())))
* Propagates actions to further middleware until the end through `next`
* May not propagate actions to further middleware ([redux.js faq](https://redux.js.org/faq/storesetup#is-it-ok-to-have-more-than-one-middleware-chain-in-my-store-enhancer-what-is-the-difference-between-next-and-dispatch-in-a-middleware-function)), but better to propagate in order not to have some actions lost in a middle of their way to the store

### [Reducer](https://redux.js.org/basics/reducers)
* Pure function
* Business logic of handling actions
* Can propagate actions to domain reducers
* ??? May not propagate actions to domain reducers
* [Recipes about structuring reducers](https://redux.js.org/recipes/structuringreducers)
