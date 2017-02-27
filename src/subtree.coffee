import { combineReducers } from 'redux'
import invariant from 'invariant'
import ReduxComponent from './ReduxComponent'
import createClass from './createClass'
import { willMountComponent, didMountComponent, willUnmountComponent } from './mountComponent'

##### SubtreeMixin
attachComponent = (parentComponent, key, component) ->
	# Development invariant: prevent shadowing of parent keys
	if process.env.NODE_ENV isnt 'production'
		invariant(not parentComponent[key]?, "redux-component of type #{parentComponent.displayName} (mounted at location #{parentComponent.path}) is using SubtreeMixin, and one of its children would shadow the key `#{key}` on the parent component.")
	parentComponent[key] = component
	childPath = parentComponent.path.concat( [ key ] )
	component.__willMount(parentComponent.store, childPath, parentComponent)
	component

applyDescriptor = (parentComponent, key, descriptor) ->
	attachComponent(parentComponent, key, createComponent(descriptor))

export SubtreeMixin = {
	getReducer: -> @subtreeReducer

	componentWillMount: ->
		# Sanity check that our component supports subtrees
		if process.env.NODE_ENV isnt 'production'
			invariant(typeof @getSubtree is 'function', "redux-component of type #{@displayName} (mounted at location #{@path}) is using SubtreeMixin, but does not have a getSubtree() method.")

		# Create subcomponents
		@__subtree = {}
		for key, descriptor of @getSubtree()
			@__subtree[key] = applyDescriptor(@, key, descriptor)

		# Create reducer
		reducerMap = {}
		for key, component of @__subtree
			reducerMap[key] = component.reducer
		@subtreeReducer = combineReducers(reducerMap)

	componentDidMount: ->
		didMountComponent(component) for key, component of @__subtree
		undefined

	componentWillUnmount: ->
		willUnmountComponent(component) for key, component of @__subtree
		undefined
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
