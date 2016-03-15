# createClass
```coffeescript
createClass = require 'redux-components/createClass'
createClass = ({spec}) -> ReduxComponentClass
```
Creates a component class given a specification object. Generally speaking, any function assigned to a key on the specification object will be copied into the prototype of the class and thus become available as instance methods. The exception to this rule is for certain specially-named keys which are used by redux-components to implement core component behavior. The special keys are as follows:

## Meta properties

### spec.displayName
```coffeescript
spec.displayName = string
```
If specified, gives a name to this component that can be used by debugging and development tools.

> Just as with React, relying on displayName to do type checking in production is an antipattern. Use the instanceof operator.

### spec.statics
```coffeescript
spec.statics = { ... }
```
All keys and values from ```spec.statics``` are merged onto the constructor for the component class via ```Object.assign```. This makes them available as "static methods" on the class constructor.

### spec.mixins
```coffeescript
spec.mixins = [ {spec}, {spec}, ... ]
```
An array of additional specs that will be mixed into this spec before creating the class. Mixins are processed in the order they appear in the array. In general, the keys on the mixin specs will be assigned to the base spec as with ```Object.assign```, with auto-binding for functions. There is special behavior for certain keys. See [Mixins](Mixins.md) for more.

## Lifecycle methods

### spec.componentWillMount
```coffeescript
spec.componentWillMount = =>
```
Invoked on a component instance immediately before its reducer is attached to the state tree. If this component has a pre-hydrated Redux state (e.g. from deserialization or time-travel), the scoped state for this component will be available inside this method at ```this.state```.
> When multiple nodes are mounted simultaneously via ```SubtreeMixin```, their ```componentWillMount()``` methods are called in preorder with respect to their place in the  state tree. (leaf nodes last)

### spec.componentDidMount
```coffeescript
spec.componentDidMount = =>
```
Invoked on a component instance immediately after its reducer is attached to the state tree. Actions understood by this component or its children can safely be dispatched from here.
> When multiple nodes are mounted simultaneously via ```SubtreeMixin```, their ```componentDidMount()``` methods are called in postorder with respect to their place in the  state tree. (leaf nodes first)

### spec.componentWillUnmount
```coffeescript
spec.componentWillUnmount = =>
```
Invoked on a component instance immediately before its reducer is removed from the state tree.
> * When multiple nodes are unmounted simultaneously via ```SubtreeMixin```, their ```componentWillUnmount()``` methods are called in postorder with respect to their place in the state tree. (leaf nodes first)

## Redux-related properties

### spec.getReducer
```coffeescript
spec.getReducer = => (state, action) => nextState
```
getReducer is a function that runs in the context of the component instance, and returns a reducer function that will be used for the state subtree managed by this component.

Reducers made by getReducer are automatically bound to their component instances so that they can have access to scoped properties, particularly scoped action verbs.

> **NB:**
> - After all mixins are evaluated, a final spec must have exactly one ```.getReducer```. We prefer to be unopinionated, so by default, there is no specified behavior for composing multiple reducers. (But see ```SubtreeMixin```.)

> - Do not use magic binding as an excuse to introduce impure behavior into your reducer! If you want the all the benefits of Redux, keep your reducers as pure functions of props and state. Don't make your reducer rely on non-constant properties of the redux-component, and don't be tempted to  store any state on the redux-component itself. (You can sometimes use ```getReducer``` to mimic "impure" behaviors without making your reducer itself impure.)

> - By default, redux-components will call `getReducer()` only once when your component is mounted to a state tree. If you expect your reducer to change during the Redux store's lifecycle, you must arrange for `getReducer()` to be called at appropriate times, and for `Store.replaceReducer()` to be called on your root store. If you use redux-components and `SubtreeMixin` throughout your state tree, we provide facilities for automating this.

### spec.verbs
```coffeescript
spec.verbs = [ string, string, ... ]
```
Specifies a list of action names that will be scoped to each instance of the component using the instance's path in the state tree. Verbs are scoped according to the following pattern: ```#{path}:#{verb}``` and are available on the instance object at a key corresponding to the verb root. For example, a component instance mounted at ```foo.bar``` in the state tree having a verb ```"BAZ"``` would have the scoped verb ```"foo.bar:BAZ"``` available as ```this.BAZ```.

> If you don't want a verb to be scoped, don't put it in the verbs array. Instead set it as a plain string property on the specification. It will then bypass the auto-scoping behavior.

### spec.actionCreators
```coffeescript
spec.actionCreators = { key: (args...) -> action, ... }
```
Specify the action creators associated with this component class. Each property on the ```actionCreators``` object will be bound to each component instance and made available on the instance as a method.
> **NB:** The redux-components core makes no assumptions about which middleware is present on a store.

### spec.selectors
```coffeescript
spec.selectors = { key: (state, ...) -> any, ... }
```
Specify the selectors associated with this component class. Each property on the `selectors` object will be bound to each component instance and wrapped in a function that scopes the selector to the instance's state. The net effect will be that the state argument received by the selector will point to the state subtree managed by the particular component instance, rather than the global Redux state.
> If you don't want a selector to be auto-scoped, don't put it in the selectors object. Instead set it as a property on the specification. This will bypass the auto-scoping behavior.

## Other properties

The specification's other properties will be `Object.assign()`ed onto the prototype for the class. Properties that are functions will be automatically bound to class instances by the constructor. Other properties will be available on the prototype.
