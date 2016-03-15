# SubtreeMixin
```coffeescript
SubtreeMixin = require 'redux-components/SubtreeMixin'
```

The `SubtreeMixin` is for creating components that manage a subtree of state. The state of the node is an object whose keys represent distinct subtrees. Each of these nodes has a redux-component instance mounted to it, and their reducers are combined via the standard Redux `combineReducers()` API to obtain the reducers for the parent node.

A component instance specifies its subtree by providing a method (either on the class specification or on the instance) called `getSubtree`:
```coffeescript
this.getSubtree = => {
	key: (subtreeDescriptor)
}

subtreeDescriptor =
	instanceof ReduxComponentClass OR
	instanceof ReduxComponent OR
	(state, action) -> nextState OR
	=> subtreeDescriptor
```

The `subtreeDescriptor`s are interpreted as follows:
* If the descriptor is an `instanceof ReduxComponentClass`, a new instance of a component with that class is created and mounted at the `key`.
* If the descriptor is an `instanceof ReduxComponent`, that instance is mounted at the `key`.
* If the descriptor has the signature of a reducer, it is mounted as a plain reducer at the `key`, and is not managed by a redux-component.
* If the descriptor is a function with no arguments, it is called in the context of the component instance, and its return value is matched against the previous three cases.

When a component instance with a `SubtreeMixin` is mounted to a store, references to each subcomponent are available at `this[key]`.

## Example

In vanilla Redux, a root reducer is often the result of a `combineReducers` over several reducers handling separate branches of app state. In redux-components, the corresponding pattern is a component using `SubtreeMixin` to combine several subcomponents:

```coffeescript
createClass = require 'redux-components/createClass'
SubtreeMixin = require 'redux-components/SubtreeMixin'
Foo = require 'MyComponents/Foo', ...

RootComponent = createClass {
	displayName: "Root"
	mixins: [ SubtreeMixin ]

	getSubtree: -> {
		foo: Foo
		bar: Bar
		baz: Baz
		...
	}
}
```

## Details

When a component with a `SubtreeMixin` enters `componentWillMount`, it calls `getSubtree()` and conjures the required subcomponent instances. It then runs `componentWillMount` on each subcomponent, combines the reducers using Redux `combineReducers`, and sets that as the reducer for the subtree. It adds to the component references to each subcomponent at the corresponding keys.

## Notes

> `SubtreeMixin` is an optimized implementation for the most common use case: nodes with a static shape. This is when the keys and subcomponent classes returned by getSubtree do not depend on the Redux state or change throughout the app lifecycle. For subtrees that are stateful or dynamic, see `DynamicSubtreeMixin`.
