import invariant from 'nanotools/lib/invariant'
import get from 'nanotools/lib/get'
import iteratePrototypeChain from 'nanotools/lib/iteratePrototypeChain'
import createSubject from 'observable-utils/lib/createSubject'
import getObservableFrom from 'observable-utils/lib/getObservableFrom'
slice = [].slice

export default class ReduxComponent
	constructor: ->
		if process.env.NODE_ENV isnt 'production'
			invariant(typeof @reducer is 'function', "redux-component of type #{@displayName} has no reducer.")
		@reducer = @reducer.bind(@)
		@_subject = createSubject()

	# Default reducer for a ReduxComponent is the identity reducer.
	reducer: (state, action) ->
		if state is undefined then null else state

	# Internal function which will return a proxy subject between us and the underlying
	# store.
	__getSubject: ->
		@_subject

	isMounted: -> !!(@__mounted)

	__willMount: (@store, @path = [], @parentComponent = null) ->
		invariant(
			@store?.getState and
			@store?.dispatch and
			@store?.subscribe and
			@store?.replaceReducer,
			"redux-component of type #{@displayName} was mounted without a proper Store object. Redux components may only be mounted to valid redux stores."
		)
		invariant(not @__mounted, "redux-component of type #{@displayName} was multiply mounted. This can indicate a cycle in your component graph, which is illegal. Make sure each instance is only used once in your tree. If you wish to use a component in multiple places, construct additional instances.")

		# Scope verbs
		if (verbs = @__getMagicallyBoundKeys('verbs'))
			stringPath = @path.join('.')
			(@[verb] = "#{stringPath}:#{verb}") for verb in verbs

		@componentWillMount?()
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
		delete @store
		delete @path
		delete @parentComponent
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

	Object.defineProperty(@prototype, 'displayName', {
		configurable: false
		enumerable: true
		get: ->
			(Object.getPrototypeOf(this))?.constructor?.name or '(unknown)'
	})
