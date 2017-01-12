import { combineReducers } from 'redux'
import invariant from 'invariant'
import ReduxComponent from './ReduxComponent'
import createClass from './createClass'


##### SubtreeMixin
attachComponent = (parentComponent, key, component) ->
	# XXX: invariant or warning here that key is not shadowing anything on the instance?
	parentComponent[key] = component
	childPath = parentComponent.path.concat( [ key ] )
	component.__willMount(parentComponent.store, childPath, parentComponent)
	# Return the reducer
	component.reducer

applyDescriptor = (parentComponent, key, descriptor) ->
	attachComponent(parentComponent, key, createComponent(descriptor))

export SubtreeMixin = {
	componentWillMount: ->
		# Sanity check that our component supports subtrees
		if process.env.NODE_ENV isnt 'production'
			invariant(typeof @getSubtree is 'function', "redux-component of type #{@displayName} (mounted at location #{@path}) is using SubtreeMixin, but does not have a getSubtree() method.")

		# Get the subtree structure
		subtree = @getSubtree()
		# Conjure child components and gather their reducers
		__reducerMap = {}
		for key, descriptor of subtree
			__reducerMap[key] = applyDescriptor(@, key, descriptor)
		# Create composite reducer for parent component
		reducer = combineReducers(__reducerMap)
		@getReducer = -> reducer

		# Monkey-patch didMount to call subtree didMounts in the right order.
		myDidMount = @__originalDidMount = @componentDidMount
		@componentDidMount = ->
			@[k]?.componentDidMount?() for k of __reducerMap
			myDidMount?.call(@)

	componentWillUnmount: ->
		@componentDidMount = @__originalDidMount
}

##### createComponent
SubtreeNonce = createClass {
	displayName: '(subtree)'
	mixins: [ SubtreeMixin ]
}

ReducerNonce = createClass {
	displayName: '(reducer)'
}

export createComponent = (descriptor) ->
	if descriptor instanceof ReduxComponent
		descriptor
	else if descriptor?.prototype and (descriptor.prototype instanceof ReduxComponent)
		new descriptor()
	else if typeof(descriptor) is 'object' and (not Array.isArray(descriptor))
		component = new SubtreeNonce()
		component.getSubtree = (-> descriptor)
		component
	else if typeof(descriptor) is 'function'
		if descriptor.length > 0 # this is a raw reducer
			component = new ReducerNonce()
			component.getReducer = (-> descriptor)
			component
		else # this is a function which will produce a descriptor
			throw new Error("pure reducer: descriptor function should be a reducer (must have at least one argument)")
	else
		throw new Error("invalid component descriptor")
