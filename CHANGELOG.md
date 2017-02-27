# 0.3

## 0.3.3

### SubtreeMixin changes

The new mounting system enabled a cleanup of the `SubtreeMixin` internals, including the removal of the `didMount` monkey patch. This should not be a breaking change for those following the API, but may break code relying on subtree internals.

- `SubtreeMixin` components now support dynamic mounting. (Meaning that the `SubtreeMixin` component can be dynamically mounted, not that its contents can change dynamically -- please use `redux-components-map` if you need that functionality.)

- A new documented field, `this.subtreeReducer`, exists on all `SubtreeMixin` component instances. This is the reducer obtained by `combineReducers` over the subcomponents. Using this functionality, it is now possible to write custom reducers for `SubtreeMixin` components that fallback on the combined reducer when they don't understand an action.

- The `__reducerMap` and `__originalDidMount` undocumented fields no longer exist.

### Miscellaneous

- The `Object.assign` polyfill has been removed. Your runtime must support `Object.assign` natively, or you must polyfill it yourself.

## 0.3.2

### Observable selector changes

We've made some changes to make observable selectors more convenient. None of these are breaking changes.

- All selectors on all ReduxComponents are now observable by default. It is no longer necessary to use `ObservableSelectorMixin`. `ObservableSelectorMixin` will continue to  exist for backwards compatibility, but is simply an empty mixin now.

- It is now possible to call `selector.next` even if the selector's owning component is not yet mounted. The attachment of the `Observer` to the selector will then be deferred until the component is mounted.

- The internal implementation of selectors has been refactored so that there is no penalty for the `Observable` implementation unless you actually attach an `Observer`.

## 0.3.1

### Added `component.isMounted()` API

There is now a `component.isMounted()` API which returns true when the component is mounted and false otherwise.

## 0.3.0

### **BREAKING CHANGE:** New component mounting API

In light of the architectural changes in 0.2, and because the old API was quite confusing, we've designed a new API for mounting components. The `mounter` function has been eliminated and replaced with an imperative API for mounting and unmounting.

For those managing their entire state tree with `redux-components`, the transition should be easy: replace your single `mountComponent` statement with the new `mountRootComponent`, which has the same argument signature.

Those with more complex state tree designs will want to [read the docs](https://wcjohnson.gitbooks.io/redux-components/content/docs/API/mountComponent.html).

### ReduxComponentClasses can now be used as mixins.

A `ReduxComponentClass` (the object returned by `createClass`) can now be used as a mixin on any other class. This can be used to simulate class inheritance in many use cases.

### actionDispatchers now support falsy return values

In 0.2, `actionDispatchers` were added to directly dispatch actions to a mounted component's store. They were required to return a valid Redux action. Now they may return a falsy value, in which case no action will be dispatched.

### Minor changes and fixes

- Redux is now listed as a dependency rather than a peerDependency.
- The internal `__reducerMap` variable on `SubtreeMixin` instances has been removed.

# 0.2

This is a major release that brings some changes that my team is excited about.

We want to know what you think about redux-components. As always, feel free to file an issue if you find a bug or want a feature.

We'd also love to see more people using the library. Many people in the Redux community are now catching on to this concept (e.g. [redux-interactions](https://github.com/convoyinc/redux-interactions), [redux-modules](https://github.com/procore/redux-modules)) which leads me to believe there's something important at the bottom here. If you like redux-components, tell your friends! If you're using redux-components (or another library like redux-components) tell us what works and doesn't work for you.

### **BREAKING CHANGE:** CommonJS require() cherry-picking from package root is no longer supported.

In 0.1.x, under CommonJS, you could `require()` specific submodules with e.g. `require('redux-components/createClass')`. This cherry-picking is no longer supported. Redux-components is moving to the ES Modules + Babel model, so individual submodules are exported from the `index` module.

The correct way to pick out submodules under CommonJS going forward is `{ createClass } = require('redux-components')`.

Unfortunately, the docs were written in the cherry-picking style, so users of the library are likely doing so as well. The docs have been updated to reflect the Babel+CommonJS style.

### ES2015 Module build

0.2.x now exports appropriate `jsnext:main` and `module` entries from `package.json` allowing for `import` as an ES2015 module:

```coffeescript
import { createClass } from 'redux-components'
```

CommonJS is still supported subject to the caveats above.

### Git Submodule support

Some people on my team were upset about how I broke Git submodule support in 0.1, so I fixed it for 0.2. You can now check out redux-components directly from Git as a submodule beneath some `node_modules` folder in your project. After an initial `npm install` to set up the git hooks, everything should work automatically, including a `post-merge` hook to rebuild the `lib` and `es` artifacts whenever you merge from upstream.

### Action Dispatchers

A new component specification entry, `spec.actionDispatchers`, has been added:
```coffeescript
spec.actionDispatchers = { key: (args...) => action, ... }
```

Action dispatchers are like action creators, except that they are automatically wrapped with `dispatch()` for the appropriate Redux Store when the component is mounted. Calling an action dispatcher will save you the extra step of calling `dispatch` yourself.

>**NB:** Your action dispatchers must return actions, just as action creators do.

### Reducer Indirection and Dynamic Reducers

- The `reducer` property of each `ReduxComponent` instance is now a lightweight thunk reducer that indirectly calls the last return value from `getReducer`.

- `spec.getReducer` has a new signature:
```coffeescript
spec.getReducer = (state?) => (state, action) => nextState
```

- If you register a class with a `getReducer` function taking zero arguments, the internal behavior of the `ReduxComponent` is the same as it was in 0.1.x.

- If you create a class with a `getReducer` function taking one or more arguments, the internal behavior of the `ReduxComponent` changes:
	- `getReducer` will be passed the current state of the component as its first argument.
	- The thunk reducer will call whatever you return from `getReducer`, allowing you to update your reducer dynamically.
	- Your `ReduxComponent` instance will have an `updateReducer()` method that will cause `getReducer` to be invoked. `updateReducer` is impure. **DO NOT** call `updateReducer` from inside of a reducer.

> **NB:** Dynamic reducers are an advanced and dangerous feature. You should only use them if you are completely certain that you need them. Don't forget the Redux contract!
- Reducers should be pure functions of state and action. Dynamic reducer behavior should only be used when you are sure you can honor this contract.
- In particular, you should think of "the state of your dynamic reducer" as being a part of your app's overall state.
- That means the behavior of a dynamic reducer should be a pure function of some branch of your state tree.
- If you make dynamic reducer behavior depend on stateful information that isn't stored in Redux, you are virtually guaranteed to break core Redux features like time travel and rehydration.

### Observable Selectors

A new mixin, `ObservableSelectorMixin`, has been provided. When mixed into a component, all `selectors` declared on the component will be instantiated as [ES7 Observables](https://github.com/tc39/proposal-observable) when the component is mounted.

If `componentInstance` is an instance of a component that uses `ObservableSelectorMixin`, and `selector` is one of its selectors, then `componentInstance.selector.subscribe(observer)` will invoke `observer.next(value)` whenever the value returned by the selector changes.

> The observable implementation assumes your store's state obeys the Redux contract, so `===` equality is used to compare selector values.
