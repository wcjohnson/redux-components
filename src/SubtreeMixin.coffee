"use strict"

{ combineReducers } = require 'redux'
invariant = require 'inv'
ReduxComponent = require './ReduxComponent'

attachComponent = (parentComponent, key, component) ->
	# XXX: invariant or warning here that key is not shadowing anything on the instance?
	parentComponent[key] = component
	childPath = parentComponent.path.concat( [ key ] )
	component.__willMount(parentComponent.store, childPath, parentComponent)
	parentComponent.__reducerMap[key] = component.reducer

applyDescriptor = (parentComponent, key, descriptor) ->
	if descriptor instanceof ReduxComponent
		attachComponent(parentComponent, key, descriptor)
	else if descriptor.prototype and (descriptor.prototype instanceof ReduxComponent)
		attachComponent(parentComponent, key, new descriptor())
	else if typeof(descriptor) is 'function'
		if descriptor.length > 0 # this is a raw reducer
			parentComponent.__reducerMap[key] = descriptor
		else # this is a function which will produce a reducer descriptor.
			applyDescriptor(parentComponent, key, descriptor.call(parentComponent))
	else
		invariant(false, "Invalid subtree descriptor at `#{key}`")

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
			myDidMount.call(@)

	componentWillUnmount: ->
		# Undo monkey-patch.
		delete @__reducerMap
		@componentDidMount = @__originalDidMount
}

module.exports = SubtreeMixin
