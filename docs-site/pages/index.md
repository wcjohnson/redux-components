---
title: "A component model for application state tree based on the React.js component model."
---

## Build your state using familiar patterns:
```javascript
import { ReduxComponent, action, selector } from 'redux-components'
import shallowEqual from 'nanotools/lib/shallowEqual'
import fetch from 'isomorphic-fetch'

export class MyComponent extends ReduxComponent {
  static verbs = [ 'SET' ]

  reducer(state = {}, action) {
    switch(action.type) {
      case this.SET:
        if( action.payload && (!shallowEqual(action.payload, state))) {
          return action.payload
        } else {
          return state
        }

      default:
        return state
    }
  }

  componentDidMount() {
    this.fetch()
  }

  @action({isDispatcher: true})
  set(value) {
    return { type: this.SET, payload: value }
  }

  @action({isDispatcher: true})
  fetch() {
    return dispatch => {
      fetch('http://api.myapp.com/myComponentData').then(
        response => response.json()
      ).then(
        json => dispatch({ type: this.SET, payload: json })
      )
    }
  }

  @selector({isObservable: true})
  get(state) {
    return state
  }
}
```

- **Think trees:** Just as React is a tree with a component at each node that creates virtual DOM, redux-components is a tree with a component at each node that reduces over state.

- **Keep it together:** Bundle reducers with associated actions and selectors, as in
[Ducks - Modular Redux](https://github.com/erikras/ducks-modular-redux).
Actions and selectors are scoped to each component instance,
so the component can be reused anywhere without changes.

- **Cycle of life:** Use React-like lifecycle hooks to initialize your app's whole state the right way.

## Easily compose reusable components into a tree:
```javascript
import { createComponent } from 'redux-components'
import { MyComponent } from './MyComponent'
import OtherComponent from 'component-library/OtherComponent'

function justPlainReducer(state = null, action) {
  return state
}

var rootComponent = createComponent({
  foo: new MyComponent()
  bar: new MyComponent()
  deepTree: {
    baz: new OtherComponent()
    quux: new MyComponent()
    nodeWithPureReducer: justPlainReducer
  }
})

export rootComponent
```

- **WYSIWYG:** Define your tree shape with object-literal syntax. Redux Components will automatically build
a composed reducer from your tree. Your state shape looks like the code.

- **Shape-independent:** Verbs, actions, and selectors are scoped to each component. You can mount multiple copies
of a component, reuse external components, and refactor your state tree without worrying
about the internal structure of the components.

- **Plays well with others:** Connect to other tools in the Redux ecosystem by mounting their reducers as pure functions.

## Attach it to a store:
```javascript
import { mountRootComponent } from 'redux-components'
import { rootComponent } from './rootComponent'
import { createStore } from 'redux'
import identityReducer from 'nanotools/lib/identityReducer'

var store = createStore(identityReducer)
mountRootComponent(store, rootComponent)

export store
```

- **Get started quickly:** After assembling a state tree, connect it to a Redux store using `mountRootComponent` and watch it go.

- **Works anywhere:** The `redux-components` library is unopinionated about the store it is attached to, meaning
that it works with all middleware and enhancers.

## ...then write readable, reusable state management code:
```javascript
import { rootComponent } from './rootComponent'

// Action dispatchers automatically handle dispatches to the store for you. This will
// dispatch { type: 'foo:SET', payload: 'hello world' }. Consumers of the API need
// not be aware of Redux state shape, or even that Redux is being used.
rootComponent.foo.set('hello world')

// Exposing a selector in your API will automatically select the appropriate branch
// of state tree, based on where the component is mounted. The correct Redux state
// is passed internally, not at the API surface.
assert(rootComponent.foo.get() === 'hello world')

// A deeply nested copy of the same component class is automatically scoped differently
// This will dispatch { type: 'deepTree.quux:SET', payload: 'goodbye world' }
rootComponent.deepTree.quux.set('goodbye world')
assert(rootComponent.deepTree.quux.get() === 'goodbye world')
```

- **Separate your concerns:** Your Redux components care about tree shape and dispatching actions; your
application logic cares only about your intent.

- **Enable reuse:** Write a component-based subsystem and use it in multiple applications without worrying about state shape.

- **Ease refactoring:** Keep an exposed API surface constant while internal actions, state shape, subtrees, et cetera change as much as you need them to.
