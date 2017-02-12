# mountComponent

## State tree design

Broadly speaking, there are two ways to manage your Redux state tree using redux-components. You can let redux-components manage the root of your tree (as well as all subnodes) or your state tree can be managed manually, with redux-components being mounted at one or more subnodes of the state tree.

We discuss both of these cases.

### redux-component at the root

The easiest way to use redux-components is to let it manage the root node of your state tree. In this case, a redux-component instance will be mounted at the root of the state tree, and hence will manage the root reducer. To do this, use `mountRootComponent`.

```coffeescript
{ mountRootComponent } = require 'redux-components'
mountRootComponent: (
	store = { getState, dispatch, subscribe, replaceReducer },
	componentInstance = instanceof ReduxComponent
) ->
```
`mountRootComponent` attaches a ReduxComponent to the root of the state tree, allowing it to manage the entire tree. `store` is a reference to the Redux store. The `componentInstance` is the component instance to be attached to the tree.

Internally, this function uses `store.replaceReducer()` to attach the reducer of the `componentInstance` to the Redux store, allowing it to manage the store's whole state.

If this is your use case, you will initialize your store like this:
```coffeescript
{ mountRootComponent, createClass } = require 'redux-components'
{ createStore } = require 'redux'

RootComponentClass = createClass {
	...
}
rootComponent = new RootComponentClass

# Create store with empty reducer
store = createStore( (x) -> x )
# Generate the reducer from the component tree and attach it.
mountRootComponent(store, rootComponent)
```

> * When using this approach, you can still attach reducers not managed by redux-components to nodes of your state tree beneath the root. Use `SubtreeMixin`.

### Manual mounting

If redux-components does not manage your root reducer, then you will need to mount and unmount components manually using the following API:

```coffeescript
{ willMountComponent, didMountComponent, willUnmountComponent } = require 'redux-components'
willMountComponent: (
	store = { getState, dispatch, subscribe, replaceReducer },
	componentInstance = instanceof ReduxComponent
	path = [string|number, ...]
) -> reducer

didMountComponent: (
	componentInstance = instanceof ReduxComponent
) ->

willUnmountComponent: (
	componentInstance = instanceof ReduxComponent
) ->
```

The manual mounting process works as follows: first you call `willMountComponent(store, componentInstance, path)`, providing the Redux `store`, the `componentInstance` you wish to mount, as well as the `path` from the root node of the store to the spot where the component will be mounted. The `path` is provided in the array form that would be used by `lodash.get()`.

`willMountComponent` will return a reducer, which you must then attach to your state tree at the given `path` using something like `store.replaceReducer()`. Once the reducer is in place, you must call `didMountComponent(componentInstance)` on the component in order to honor the redux-components lifecycle contract.

> * Do not manually mount components beneath redux-components that manage children, such as `SubtreeMixin` nodes or `redux-components-map`. This will bypass the internal logic of those components and almost certainly break your reducer tree. Use the correct APIs of the parent component to add child nodes beneath these components.

### Manual unmounting

If you want to unmount a manually-mounted component, you should call `willUnmountComponent(componentInstance)` on it first. This will invoke the `willUnmount` method as required by redux-components' lifecycle contract, as well as replacing the reducer for the component with the identity.

You must then manually patch up the state tree. (e.g. by calling `replaceReducer()` to remove the manually-mounted reducer) Such is the nature of manual mounting, and why we recommend letting redux-components manage your root nodes.
