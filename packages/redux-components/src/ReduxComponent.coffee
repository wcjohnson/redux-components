import invariant from 'nanotools/lib/invariant'
import get from 'nanotools/lib/get'
import identityReducer from 'nanotools/lib/identityReducer'
import iteratePrototypeChain from 'nanotools/lib/iteratePrototypeChain'
import createSubject from 'observable-utils/lib/createSubject'
import getObservableFrom from 'observable-utils/lib/getObservableFrom'
import makeSelectorObservable from './makeSelectorObservable'
slice = [].slice

# Indirect reducer to allow components to dynamically update reducers.
indirectReducer = (state, action) ->
	@__internalReducer.call(@, state, action)

export default class ReduxComponent
	constructor: ->
		@__internalReducer = identityReducer
		@reducer = indirectReducer.bind(@)
		@_subject = createSubject()

	# Internal function which will return a proxy subject between us and the underlying
	# store.
	__getSubject: ->
		@_subject

	updateReducer: ->
		# XXX: should we invariant() that the reducer is an actual reducer?
		if process.env.NODE_ENV isnt 'production'
			invariant(typeof @getReducer is 'function', "redux-component of type #{@displayName} (mounted at location #{@path}) is updating its reducer, but does not have a getReducer() method.")
		@__internalReducer = @getReducer(@state)
		return

	isMounted: -> !!(@__mounted)

	__willMount: (@store, @path = [], @parentComponent = null) ->
		invariant(@store, "redux-component of type #{@displayName} was mounted without a proper Store object. Redux components may only be mounted to valid redux stores.")
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
		# Connect internal subject to store.
		@_subject.subscription = getObservableFrom(@store).subscribe(@_subject)
		# Execute handlers
		@componentDidMount?()
		return

	__willUnmount: ->
		invariant(@__mounted, "redux-component of type #{@displayName} was unmounted when not mounted. This can indicate an issue in a dynamic reducer component such as redux-components-map.")
		@componentWillUnmount?()
		# Disconnect selectors from store
		@_subject.subscription?.unsubscribe()
		delete @_subject.subscription
		@__internalReducer = identityReducer
		delete @store
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
			if @store? then get(@store.getState(), @path) else undefined
	})
