import invariant from 'nanotools/lib/invariant'
import get from 'nanotools/lib/get'
import identityReducer from 'nanotools/lib/identityReducer'
import iteratePrototypeChain from 'nanotools/lib/iteratePrototypeChain'
import makeSelectorObservable from './makeSelectorObservable'
slice = [].slice

# Indirect reducer to allow components to dynamically update reducers.
indirectReducer = (state, action) ->
	@__internalReducer.call(@, state, action)

export default class ReduxComponent
	constructor: ->
		@__internalReducer = identityReducer
		@reducer = indirectReducer.bind(@)
		for key in @__getMagicallyBoundKeys('magicBind')
			@[key] = @[key].bind(@)

	updateReducer: ->
		# XXX: should we invariant() that the reducer is an actual reducer?
		if process.env.NODE_ENV isnt 'production'
			invariant(typeof @getReducer is 'function', "redux-component of type #{@displayName} (mounted at location #{@path}) is updating its reducer, but does not have a getReducer() method.")
		@__internalReducer = @getReducer(@state)
		return

	isMounted: -> !!(@__mounted)

	__willMount: (@store, @path = [], @parentComponent = null) ->
		invariant(not @__mounted, "redux-component of type #{@displayName} was multiply initialized. This can indicate a cycle in your component graph, which is illegal. Make sure each instance is only used once in your tree. If you wish to use a component in multiple places, construct additional instances.")

		# Scope verbs
		if (verbs = @__getMagicallyBoundKeys('verbs'))
			stringPath = @path.join('.')
			(@[verb] = "#{stringPath}:#{verb}") for verb in verbs

		@componentWillMount?()
		@updateReducer()
		return

	__didMount: ->
		@__mounted = true
		# Magic-bind selectors
		for key in @__getMagicallyBoundKeys('selectors')
			@[key]?.mount?()
		# Execute handlers
		@componentDidMount?()
		return

	__willUnmount: ->
		invariant(@__mounted, "redux-component of type #{@displayName} was unmounted when not mounted. This can indicate an issue in a dynamic reducer component such as redux-components-map.")
		@componentWillUnmount?()
		# Disconnect selectors from store
		for key in @__getMagicallyBoundKeys('selectors')
			@[key]?.unmount?()
		@__internalReducer = identityReducer
		delete @__mounted
		return

	__getMagicallyBoundKeys: (type) ->
		result = []
		iteratePrototypeChain(@, (proto) ->
			result = result.concat(proto.constructor?[type] or [])
		)
		result

	Object.defineProperty(@prototype, 'state', {
		configurable: false
		enumerable: true
		get: ->
			get(@store.getState(), @path)
	})
