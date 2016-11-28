# Dynamic Reducers

It is occasionally necessary to modify reducer behavior within a running app, as evidenced by Redux's own `store.replaceReducer` function. In 0.2, Redux Components is introducing its own version of this behavior, which allows you to build predictable dynamic reducer behaviors into your components.

> **NB:** Dynamic reducers are an advanced and dangerous feature. It is very easy to break the Redux contract by abusing a dynamic reducer. Dynamic reducers are rarely necessary and you should only use them if you are completely certain that you need them. As correct dynamic reducers are tricky to write, you should also prefer pre-written and tested libraries that use dynamic reducers to writing your own whenever practical.

## When do I need a dynamic reducer?

If your reducer needs to behave in a fundamentally different way based on the state of your application, and you **cannot** implement this behavior as a single pure function of state, then you need a dynamic reducer.

An example is the `ComponentMap` class implemented in [redux-component-map](https://github.com/wcjohnson/redux-components-map), which allows Redux Components to be dynamically mounted and unmounted from a node of the state tree of a live application.

In order to implement this behavior, it is necessary to define a new reducer function each time the tree of components changes, because the reducer function is a composition of other functions and the composition depends on the shape of the tree. This is the typical use case for which dynamic reducers were developed.

Dynamic reducers are dangerous in general. Most of the time someone needs a dynamic reducer, it is basically to implement `Map` or something like it. If that's you, consider redux-component-map before writing your own.

## How do I create a component with a dynamic reducer?

If you [specify a component](/docs/API/ComponentSpecification.md) with a `getReducer` function taking zero arguments, you are creating a `ReduxComponent` with a *static reducer*. `getReducer` will be called once, when the component is mounted, and never again throughout the lifecycle.

If, however, you specify a `getReducer` function taking one or more arguments (as measured by `Function.length`), you are specifying a *dynamic reducer*. If you do this, then the internal behavior of the component changes:

- `getReducer` will be passed the current state of the component at call-time as its first argument.
- The final component will have a thunk reducer that will call whatever you most recently returned from `getReducer`, allowing you to update your reducer dynamically.
- Your component instance will have an `updateReducer()` method that will cause `getReducer` to be invoked. `updateReducer` is impure. **DO NOT** call `updateReducer` from inside of a reducer.

## What are the dangers of dynamic reducers?

- You should think of "the state of your dynamic reducer" as part of your app's state. When Redux rehydrates your store from a serialized state, you must ensure your dynamic reducer can be recovered during the hydration. Like reducers themselves, the `getReducer()` that produces your dynamic reducers must be a pure function of state. If your `getReducer()` impurely depends on app state that is outside of Redux, you are virtually guaranteed to break the Redux contract and lose coherence under state rehydration.

- You are responsible for keeping your reducer up to date. In particular, you must arrange for `updateReducer()` to be called whenever a state change would impact your dynamic reducer. If you do not synchronize this correctly, you will again almost certainly break Redux's contract.

- `updateReducer()` is of course an impure operation and cannot be called within a reducer. Thus you must ensure that your synchronization system runs in an impure context, e.g. on `store.subscribe()`. Observable selectors can help you implement this pattern correctly.
