# mountComponent
```coffeescript
mountComponent = require 'redux-components/mountComponent'
mountComponent: (store = { getState, dispatch, subscribe, replaceReducer }, componentInstance = instanceof ReduxComponent, path = [string|number, ...], mounter = (store, componentInstance) ->) ->
```
Mounts a component instance to the redux state tree. `store` is a reference to the Redux store. The `componentInstance` is the component instance to be attached to the tree. The `path` is an array path from the root node of the state tree to the node at which this component will be mounted.

The `mounter` is a function that will be called as the component is mounting, and additionally whenever the subtree managed by this component requests a change in reducer. It should have the effect of replacing the store's root reducer via `store.replaceReducer()` as appropriate.

## State tree design

### Root managed by redux-components; connected subtrees

In this case, a redux-component instance will be mounted at the root of the state tree, and hence will manage the root reducer. You will only ever call `mountComponent` once, to connect this root component. Trees of subcomponents descending from the root will be managed by `SubtreeMixin`.

We expect this to be the typical (or if not typical, then certainly simplest) case and so we provide a default implementation of `mounter` for this scenario:

```coffeescript
mounter = (store, componentInstance) ->
	store.replaceReducer(componentInstance.reducer)
```

If this is your use case, you will initialize your store like this:
```coffeescript
mountComponent = require 'redux-components/mountComponent'
createClass = require 'redux-components/createClass'
{ createStore } = require 'redux'

RootComponentClass = createClass {
	...
}
rootComponent = new RootComponentClass

# Create store with empty reducer
store = createStore( (x) -> x )
# Generate the reducer from the component tree and attach it.
mountComponent(store, rootComponent)
```

> * When using this approach, you can still attach reducers not managed by redux-components to nodes of your state tree beneath the root. Use `SubtreeMixin`.
> * If you need to use a higher-order reducer at the root of your state tree, you must provide a `mounter` that wraps `componentInstance.reducer` in your higher-order reducer before attaching it to the store.
> * Don't disconnect subtrees of redux-components! Every redux-component should have a parent that is a redux-component, except the unique root component at the top of the tree. If this is not so, you are in the (more difficult) case described below.

### Unmanaged root and/or disconnected subtrees

We strongly recommend allowing redux-components to manage your root reducer if possible. It makes everything work better. But maybe this is impossible for your use case.

If so, you can implement a design where you will manage your own state tree from the root, with one or more subtrees managed by redux-components. You will call `mountComponent` for each such subtree. For each component you mount, you must provide your own implementation of `mounter` that will rebuild and reattach the root reducer, taking into account the fact that the `mountedInstance`'s reducer may have changed.

> If you have multiple disconnected subtrees managed by redux-components, the `mounter` for each subtree must be aware of the others and reattach their reducers correctly!
