# redux-components
A component model for Redux state trees based on the React.js component model.

## Documentation
[GitBook format](https://wcjohnson.gitbooks.io/redux-components/content/)

## What's it for?
redux-components is designed to boost reusability and composability in Redux apps by exploiting familiar design patterns from the React ecosystem.

Create reusable, extensible classes of Redux components using patterns based on [Ducks - Modular Redux](https://github.com/erikras/ducks-modular-redux) and [React](https://facebook.github.io/react/):
```coffeescript
{ createClass } = require 'redux-components'

ObjectStore = createClass {
	displayName: 'ObjectStore'

	verbs: ['SET', 'MERGE'] # !! Declare verb stems; verbs are automatically scoped to path of component.

	getReducer: -> (state, action) ->
		switch action.type
			when @SET # !! Reducer can switch on scoped verbs.
				if isEqual(state, action.payload) then state else Object.assign({}, action.payload)
			when @MERGE
				maybeNextState = Object.assign({}, state, action.payload)
				if isEqual(state, maybeNextState) then state else maybeNextState
			else
				state

	actionCreators: {
		set: (obj) -> { type: @SET, payload: obj } # !! Action creators can depend on scoped verbs.
		merge: (obj) -> { type: @MERGE, payload: obj }
	}

	selectors: {
		get: (state) -> state # !! Selectors are scoped to the component's state subtree.
	}
}
```

Compose many of them easily into a state tree:
```coffeescript
{ createStore } = require 'redux'
{ createComponent, mountComponent } = require 'redux-components'

root = createComponent {
	foo: ObjectStore
	bar: ObjectStore
	deep: {
		baz: ObjectStore
	}
}

store = createStore( (x) -> x )
mountComponent(store, root)
```

Scoped action creators and selectors operate on individual reusable components:
```coffeescript
store.dispatch( root.foo.set( {iam: 'foo'} ) )
store.dispatch( root.deep.baz.set( {iam: 'deep.baz'} ) )
root.foo.get() # { iam: 'foo' }
root.deep.baz.get() # { iam: 'deep.baz' }
```

In addition to the above, you get:
- Mixins.
- Lifecycle methods.
- Dynamic mounting and unmounting of state subtrees.
- Designed using pure reducers, written against the public Redux API, and no middleware. This means full compatibility with other Redux middlewares, reducers, enhancers, etc.

Please see [the GitBook docs](https://wcjohnson.gitbooks.io/redux-components/content/) for much more information.
