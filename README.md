# redux-components

[![Join the chat at https://gitter.im/redux-components/Lobby](https://badges.gitter.im/redux-components/Lobby.svg)](https://gitter.im/redux-components/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
A component model for Redux state trees based on the React.js component model and other familiar design patterns from the React ecosystem.

## What's New

- We've been making a lot of great improvements. Check out the [Change Log](CHANGELOG.md) for details -- particularly if you are moving to a higher significant version digit!

- Check out [redux-components-map](https://github.com/wcjohnson/redux-components-map) for a solution to a common use case: dynamic tree structure changes while your app is running.

## Documentation
> **NB:** redux-components is a tool that interoperates with [Redux](http://redux.js.org/). This documentation presumes a solid grasp of the fundamentals found in the [Redux docs](http://redux.js.org) -- particularly the concepts of the Redux state tree, reducers, action creators, and selectors.

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
- A system designed using pure reducers, written against the public Redux API, that uses no middleware. This means full compatibility with other Redux middlewares, reducers, enhancers, etc.

Please see [the GitBook docs](https://wcjohnson.gitbooks.io/redux-components/content/) for much more information.
