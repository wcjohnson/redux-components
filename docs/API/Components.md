# Components
As in React, components are built up from the JavaScript object model. One creates a component class by passing a specification object to  [createClass](createClass.md). Unlike React, there is no analogue of `createElement` in redux-components. One instantiates a class with JavaScript object construction: `new Class()`.

> The constructor function built by createClass will automatically create instances if not called with new, so `Class()` will work as well as `new Class()`.

## Component Instances

Instances of component classes are, in effect, ducks, each having as members a reducer along with related action verbs, action creators, and selectors. A class is then a template for creating ducks that can be reused in an app or transported to other apps.

Instances have the following members:

### this.state
```coffeescript
this.state = any
```
A reference to the scoped subtree of the current Redux state at the mount position of this component instance.

### this.store
```coffeescript
this.store = { getState, dispatch, subscribe, replaceReducer }
```
A reference to the Redux store to which this instance is mounted.

### this.parentComponent
```coffeescript
this.parentComponent = (instanceof ReduxComponent)?
```
A reference to the component instance mounted at the parent node of the state tree, if any.

### this.path
```coffeescript
this.path = [ string|number, ... ]
```
Array describing the path from the root of the state tree to the mounted position of this component, as in the second argument of `lodash.get()`.

### this.reducer
```coffeescript
this.reducer = (state, action) => nextState
```
The reducer function for this component instance, as obtained by the `getReducer` function on the class specification.

### Verbs, action creators, and selectors
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

Action creators from the `actionCreators` object on the class specification will be available on each instance as automatically-bound functions. Selectors from the `selectors` object on the class specification will be available on each instance. They will be automatically bound and wrapped in a function that invokes them with the scoped state, rather than the global state. See [createClass](createClass.md) for more information.

> If you want unscoped action creators, selectors, or verbs, assign them at the top level of the specification object. See [createClass](createClass.md) for more.

### Misc
Other properties of the descriptor object are merged onto the class prototype, with functions being auto-bound to instances.
