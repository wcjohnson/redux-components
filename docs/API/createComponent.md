# createComponent
```coffeescript
createComponent = require 'redux-components/createComponent'
createComponent = (descriptor) -> instanceof ReduxComponent

descriptor =
	instanceof ReduxComponent      | # Component passthru
	instanceof ReduxComponentClass | # Component instantiation
	{ key: descriptor, ... }       | # Pure subtree
	(state, action) -> nextState     # Pure reducer
```
Creates a [component instance](Components.md) given a descriptor. Analogous to `ReactDOM.createElement()` in React.

### Descriptor types

#### Component passthru
If you pass an object that is already an instantiated `ReduxComponent`, it will be returned identically.

#### Component instantiation
If you pass the constructor of a `ReduxComponentClass`, `createComponent` will instantiate that class via `new Class()` and return the new instance.

#### Pure subtree
If you pass an object, `createComponent` will construct an instance of a "pure subtree" component. The component is made using [SubtreeMixin](SubtreeMixin.md). For each property of the descriptor object, the property value will be instantiated using `createComponent` and the resulting component instance will be attached to the corresponding key.

#### Pure reducer
If you pass a function with one or two arguments, `createComponent` will construct an instance of a "pure reducer" component. The component will have the given function as its reducer, and no other special properties.

> Pure subtrees and pure reducers can be thought of as the redux-components analogue of React's "stateless functional components." They wrap the two most common use cases in a facade that is syntactically and semantically cleaner.
