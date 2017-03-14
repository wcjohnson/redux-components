import invariant from 'nanotools/lib/invariant'
import get from 'nanotools/lib/get'
import identityReducer from 'nanotools/lib/identityReducer'
import iteratePrototypeChain from 'nanotools/lib/iteratePrototypeChain'
import makeSelectorObservable from './makeSelectorObservable'
slice = [].slice

# Indirect reducer to allow components to dynamically update reducers.
indirectReducer = (state, action) ->
	@__internalReducer.call(@, state, action)

# Bind an action to automatically dispatch to the right store.
dispatchAction = (actionCreator, self) -> ->
	action = actionCreator.apply(self, arguments)
	if action? then self.store.dispatch(action)

# Scope a selector to a component.
scopeSelector = (sel, self) -> ->
	fwdArgs = slice.call(arguments)
	fwdArgs[0] = self.state
	sel.apply(self, fwdArgs)

performMagicBinding = (proto) ->
	constructor = proto.constructor
	if not constructor then return

	if constructor.magicBind
		for key in constructor.magicBind
			func = @[key]
			if typeof func is 'function' then @[key] = func.bind(@)

	if constructor.actionCreators
		for key in constructor.actionCreators
			func = @[key]
			if func then @[key] = func.bind(@)

	if constructor.actionDispatchers
		for key in constructor.actionDispatchers
			func = @[key]
			if func then @[key] = dispatchAction(func, @)

	if constructor.selectors
		for key in constructor.selectors
			func = @[key]
			scoped = scopeSelector(func, @)
			@[key] = makeSelectorObservable(@, scoped)

	return

export default class ReduxComponent
	constructor: ->
		@__internalReducer = identityReducer
		@reducer = indirectReducer.bind(@)
		iteratePrototypeChain(@, performMagicBinding.bind(@))

	updateReducer: ->
		# XXX: should we invariant() that the reducer is an actual reducer?
		if process.env.NODE_ENV isnt 'production'
			invariant(typeof @getReducer is 'function', "redux-component of type #{@displayName} (mounted at location #{@path}) is updating its reducer, but does not have a getReducer() method.")
		@__internalReducer = @getReducer(@state)
		undefined

	isMounted: -> !!(@__mounted)

	__willMount: (@store, @path = [], @parentComponent = null) ->
		invariant(not @__mounted, "redux-component of type #{@displayName} was multiply initialized. This can indicate a cycle in your component graph, which is illegal. Make sure each instance is only used once in your tree. If you wish to use a component in multiple places, construct additional instances.")

		# Scope verbs
		if (verbs = @constructor.verbs)
			stringPath = @path.join('.')
			(@[verb] = "#{stringPath}:#{verb}") for verb in verbs

		@componentWillMount?()
		@updateReducer()
		undefined

	__didMount: ->
		@__mounted = true
		# Magic-bind selectors
		for key in @__getMagicallyBoundKeys('selectors')
			@[key]?.mount?()
		# Execute handlers
		@componentDidMount?()
		undefined

	__willUnmount: ->
		invariant(@__mounted, "redux-component of type #{@displayName} was unmounted when not mounted. This can indicate an issue in a dynamic reducer component such as redux-components-map.")
		@componentWillUnmount?()
		# Disconnect selectors from store
		for key in @__getMagicallyBoundKeys('selectors')
			@[key]?.unmount?()
		@__internalReducer = identityReducer
		delete @__mounted

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
