# Motivation

> **NB:** redux-components is a [Redux](http://redux.js.org/) extension. This documentation presumes familiarity with Redux concepts. At a minimum, you should have a solid grasp of the basics in the [Redux docs](http://redux.js.org).

### Redux, Reuse, Recycle

I happened upon [Redux](http://redux.js.org) after being bitten by considerable problems at the interface of Backbone.js with [React.js](https://facebook.github.io/react/). Five minutes of having a single, perfect audit trail of everything that ever happened in my app convinced me that I was looking at the inevitable future. I pitched it to the team and we decided to try a small-scale experiment in transitioning to Redux.

We had made a previous transition from Angular to React, and the React component model was so conducive to code reuse that it gave us a force-multiplication effect. Since going to React we've leveraged the drop-in reusability of React components to great success within our team.

I thought my best chance at successfully pitching Redux would turn on whether I could  duplicate the force-multiplication effect that we got from the React component model within Redux. This would mean being able to take pieces of Redux state management code and package them to be dropped into subsequent apps with the expectation that it will just work. Some digging in the ecosystem for the existing community consensus on these things led me to [Ducks - Modular Redux](https://github.com/erikras/ducks-modular-redux), and I began developing the  Redux stores in our experimental app according to the "duck" pattern.

I soon discovered that ducks by themselves didn't quite check all the boxes I needed.

### The ObjectStore duck -- a toy example

Consider a commonly recurring pattern in Redux state design: a leaf node in a state tree that stores a Javascript object that is opaque to the reducer. The reducer will respond to two actions, ```SET``` and ```MERGE```, which will do the obvious mutations on the next state, making a new state only if there was a change. In this example, we will assume it lives at a node named ```widget``` at the top of the Redux state tree. According to the duck model, the implementation looks something like this:

> **NB:** Example code is in CoffeeScript targeting CommonJS, and as such deviates slightly from the standard 'duck' pattern in that the reducer is exported as 'reducer' rather than as the default export.

```coffeescript
#### state/ducks/widget/index.coffee
SET = 'widget:SET'
MERGE = 'widget:MERGE'

reducer = (state = {}, action) ->
	switch action.type
		when SET
			if isEqual(state, action.payload) then state else Object.assign({}, action.payload)
		when MERGE
			maybeNextState = Object.assign({}, state, action.payload)
			if isEqual(state, maybeNextState) then state else maybeNextState
		else
			state

# Action Creators
setWidget = (widget) -> { type: SET, payload: widget }

mergeWidget = (widget) -> { type: MERGE, payload: widget }

fetchWidget = (widget) -> (dispatch) ->
	fetch("http://widgets.com/myCoolWidget")
	.then (resp) -> resp.json()
	.then (obj) -> dispatch(mergeWidget(obj))

# Selectors
selectWidget = (state) -> state.widget

module.exports = { reducer, setWidget, mergeWidget, fetchWidget, selectWidget }
```

### But is it really a toy?

In the course of developing with the "duck" model, our team realized that probably 50% of the nodes our Redux state tree were basically ```ObjectStore```s with a little bit of window dressing in the form of value-add selectors and action creators. If you add in the slightly more complex ```KeyValueStore```s (XXX: code to be included in examples repository) it's probably closer to 90% between the two of them.

We were basically using copypasta to spread this duck throughout our state tree in our initial implementation. This was clearly not the way to go. Finding the "right" way to reuse this ```ObjectStore``` duck is going to be a big win, despite its relatively trivial nature.

How best to do that, though? The first two obvious problems are:
* You need different action names for each distinct ```ObjectStore``` node in your state tree (unless, of course, you actually want them to mutate simultaneously in response to actions, which you very likely don't.)

* Anything that refers to the state of your ```ObjectStore```, e.g. selectors and thunked action creators, will need to be abstracted to traverse the appropriate path from the root of the state tree to the right node.

### Try #1: Higher-Order Ducks

The first possible fix is to wrap the whole duck in a closure over where it is in the tree:

```coffeescript
#### state/hoducks/ObjectStore.coffee
mountObjectStoreAt = (path) ->
	SET = "#{path}:SET"
	MERGE = "#{path}:MERGE"

	reducer = (state = {}, action) ->
		switch action.type
			when SET
				if isEqual(state, action.payload) then state else Object.assign({}, action.payload)
			when MERGE
				maybeNextState = Object.assign({}, state, action.payload)
				if isEqual(state, maybeNextState) then state else maybeNextState
			else
				state

	# Action Creators
	set = (obj) -> { type: SET, payload: obj }

	merge = (obj) -> { type: MERGE, payload: obj }

	fetch = (widget) -> (dispatch) -> # !!!
		fetch("http://widgets.com/myCoolWidget")
		.then (resp) -> resp.json()
		.then (obj) -> dispatch(mergeWidget(obj))

	# Selectors
	selectWidget = (state) -> _.at(state, path)?.widget

	{ reducer, setWidget, mergeWidget, selectWidget }

module.exports = mountObjectStoreAt
```

Then you can create "instances" of the ```ObjectStore``` duck that you can reuse throughout your state tree:

```coffeescript
#### state/stateTree.coffee
mountObjectStoreAt = require 'state/hoducks/ObjectStore'

widgetNode = mountObjectStoreAt("widget")
whatsitNode = mountObjectStoreAt("whatsit")
deepBazNode = mountObjectStoreAt("foo.bar.baz")

rootReducer = combineReducers({
	widget: widgetNode.reducer
	whatsit: whatsitNode.reducer
	foo: combineReducers({
		bar: combineReducers({
			baz: deepBazNode.reducer
			...
		})
		...
	})
})

module.exports = { widgetNode, whatsitNode, deepBazNode, reducer: rootReducer } # ????
```

We're getting somewhere! Notice how the code to create the rootReducer is starting to look like a react-router routing tree, and the things at the nodes are conceptually starting to look like the React components that handle your routes. This is not a coincidence, and it's an analogy we're going to push all the way to the end to get redux-components.

Anyway, we're on to something here, but it's still not perfect.

Some specific issues:

* Tree refactoring. When playing this game, we have to keep two things in sync: the combineReducer tree and the string paths. This makes refactoring the tree needlessly difficult. To alleviate this, the combineReducer tree should "inject" the parent path to child nodes like react-router does. There should be a single source of truth for how the state tree looks.

* How do we keep fetch (and more complex action creators in general) generic, portable from node to node, and reusable?

* We need references to the objects returned by mountObjectStoreAt() so that we can call our reusable action creators and selectors. We could export them from the state tree's root module (ugh) or break them out into separate files (in practice you will end up doing this anyway, so not as bad as it sounds), but we'd like a nicer way of getting at them.

### Try #*n*: redux-components

* ...fit directly into the Redux model as pure reducers managing specific subtrees of serializable state. All reducers generated by redux-components are pure functions of state and action. (In fact, at bottom they are generated either by you or Redux's own ```combineReducers()```) It is compatible with Immutable or any other storage system that works with vanilla ```combineReducers()```. It will not break time-travel debugging, hot reloading, or other tools that serialize state.

* ...are, as a result of the preceding design choice, fully compatible and coexistent with all plugins, modules, ducks, etc. in the redux ecosystem, even if they don't use or aren't aware of redux-components. Your redux-components touch only the branches of your state tree that you design them to.

* ...are designed in accordance with a conceptual (and syntactical) analogy with React components, making adoption easy for those familiar with the React model.

* ...are aware of their location in the state tree, making them robust against refactoring and transportable to other Redux-based applications.

* ...are dynamically mountable and unmountable from the state tree at any time.

* ...allow you to write selectors and action creators under an assumption of state locality, similar to the state locality that ```combineReducers()``` gives you for child reducers.
