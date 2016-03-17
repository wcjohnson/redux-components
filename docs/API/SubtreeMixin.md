# SubtreeMixin
```coffeescript
SubtreeMixin = require 'redux-components/SubtreeMixin'
```

The `SubtreeMixin` is for creating components that manage a subtree of state. The state of the node is an object whose keys represent distinct subtrees. Each of these nodes has a redux-component instance mounted to it, and their reducers are combined via the standard Redux `combineReducers()` API to obtain the reducer for the parent node.

A component instance specifies its subtree by providing a method (either on the class specification or on the instance) called `getSubtree`:
```coffeescript
this.getSubtree = => {
	key: componentDescriptor
	...
}
```

When the parent component is mounted, child components are instantiated using `createComponent(componentDescriptor)`. See [createComponent docs](createComponent.md) for details on `componentDescriptor`s. References to each child components are placed on the parent component at `this[key]`, where `key` is the key of the child in the subtree map.

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
