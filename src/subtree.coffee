"use strict"

{ combineReducers } = require 'redux'
invariant = require 'inv'
ReduxComponent = require './ReduxComponent'
createClass = require './createClass'

##### SubtreeMixin
attachComponent = (parentComponent, key, component) ->
	# XXX: invariant or warning here that key is not shadowing anything on the instance?
	parentComponent[key] = component
	childPath = parentComponent.path.concat( [ key ] )
	component.__willMount(parentComponent.store, childPath, parentComponent)
	parentComponent.__reducerMap[key] = component.reducer

applyDescriptor = (parentComponent, key, descriptor) ->
	attachComponent(parentComponent, key, createComponent(descriptor))

SubtreeMixin = {
	componentWillMount: ->
		subtree = @getSubtree(); @__reducerMap = {}
		# Conjure child components
		for key, descriptor of subtree
			applyDescriptor(@, key, descriptor)

		# Create reducer
		reducer = combineReducers(@__reducerMap)
		@getReducer = -> reducer

		# Monkey-patch didMount to call subtree didMounts in the right order.
		myDidMount = @__originalDidMount = @componentDidMount
		@componentDidMount = =>
			@[k]?.componentDidMount?() for k of @__reducerMap
			myDidMount?.call(@)

	componentWillUnmount: ->
		# Undo monkey-patch.
		delete @__reducerMap
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

createComponent = (descriptor) ->
	if descriptor instanceof ReduxComponent
		descriptor
	else if descriptor.prototype and (descriptor.prototype instanceof ReduxComponent)
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

module.exports = { createComponent, SubtreeMixin }
