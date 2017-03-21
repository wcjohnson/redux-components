# Components

## Component Classes

As in React, components are built up from the JavaScript object model. One creates a component class by passing a [specification object](ComponentSpecification.md) to  [createClass](createClass.md). To instantiate an instance of the class, which can then be mounted to a Redux state tree, use [createComponent](createComponent.md), which is the analogue of React's `createElement`:
```coffeescript
componentInstance = createComponent(ComponentClass)
```

> * `createClass` returns a JavaScript constructor function, so it is acceptable to call `new Class()` to create a new instance. This is what `createComponent` does internally. The constructor function built by `createClass` will automatically create instances if not called with `new`, so `Class()` will work as well as `new Class()`.

> * `createComponent` has some magic syntax for common use cases. See the [createComponent docs](createComponent.md).

## Component Instances

Instances of component classes are, in effect, ducks, each having as members a reducer along with related action verbs, action creators, and selectors. A class is then a template for creating ducks that can be reused in an app or transported to other apps.

Instances have the following members:

### Lifecycle methods

#### componentWillMount
```coffeescript
this.componentWillMount = =>
```
Invoked on a component instance immediately before its reducer is attached to the state tree. If there is a pre-hydrated Redux state (e.g. from deserialization or time-travel), the scoped state for this component will be available inside this method at ```this.state```.

During this method, the component's reducer has **NOT** yet been attached to the Redux store, so it will not see any actions dispatched to the store. If you need to dispatch actions you expect this component to see, wait until `componentDidMount`.
> When multiple nodes are mounted simultaneously, their ```componentWillMount()``` methods are called in postorder with respect to their place in the  state tree. (leaf nodes first)

#### componentDidMount
```coffeescript
this.componentDidMount = =>
```
Invoked on a component instance immediately after its reducer is attached to the state tree. Actions understood by this component or its children will be seen by the appropriate reducers if dispatched from here.
> When multiple nodes are mounted simultaneously, their ```componentDidMount()``` methods are called in postorder with respect to their place in the  state tree. (leaf nodes first)

#### componentWillUnmount
```coffeescript
this.componentWillUnmount = =>
```
Invoked on a component instance immediately before its reducer is removed from the state tree.
> When multiple nodes are unmounted simultaneously, their ```componentWillUnmount()``` methods are called in postorder with respect to their place in the state tree. (leaf nodes first)

#### isMounted
```coffeescript
this.isMounted = => boolean
```
Returns `true` if the component's reducer is mounted to the Redux store, `false` otherwise.

### Redux state

#### this.state
```coffeescript
this.state = any
```
A reference to the scoped subtree of the current Redux state at the mount position of this component instance.

#### this.store
```coffeescript
this.store = { getState, dispatch, subscribe, replaceReducer }
```
A reference to the Redux store to which this instance is mounted.

#### this.parentComponent
```coffeescript
this.parentComponent = (instanceof ReduxComponent)?
```
A reference to the component instance mounted at the parent node of the state tree, if any.

#### this.path
```coffeescript
this.path = [ string|number, ... ]
```
Array describing the path from the root of the state tree to the mounted position of this component, as in the second argument of `lodash.get()`.

#### this.reducer
```coffeescript
this.reducer = (state, action) => nextState
```
The reducer function for this component instance.

#### Verbs, action creators, and selectors
```coffeescript
this.SCOPED_VERB = "path.to.instance:SCOPED_VERB"
```
```coffeescript
this.anActionCreator = (...) => any
```
```coffeescript
this.aSelector = (scopedState, ...) => any
```
Action verbs (the strings that are used as Redux action types) from the `verbs` array on the class specification will be available in scoped format on each instance.

Action creators from the `actionCreators` object on the class specification will be available on each instance as automatically-bound functions.

Selectors from the `selectors` object on the class specification will be available on each instance. They will be automatically bound and wrapped in a function that invokes them with the scoped state, rather than the global state. See [createClass](createClass.md) for more information.

> If you want unscoped action creators, selectors, or verbs, assign them at the top level of the specification object. See [createClass](createClass.md) for more.

### Misc
Other properties of the descriptor object are merged onto the class prototype, with functions being auto-bound to instances.
