import invariant from 'invariant'
import { get, nullIdentity } from './util'
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

iteratePrototypeChain = (obj, func) ->
	proto = Object.getPrototypeOf(obj)
	while (proto isnt null) and (proto.constructor isnt Object)
		func(proto, obj)
		proto = Object.getPrototypeOf(proto)
	return

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
		@__internalReducer = nullIdentity
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
		#@reducer = indirectReducer.bind(@)
		@updateReducer()
		undefined

	__didMount: ->
		@__mounted = true
		@componentDidMount?()
		undefined

	__willUnmount: ->
		invariant(@__mounted, "redux-component of type #{@displayName} was unmounted when not mounted. This can indicate an issue in a dynamic reducer component such as redux-components-map.")
		@componentWillUnmount?()
		@__internalReducer = nullIdentity
		delete @__mounted

	Object.defineProperty(@prototype, 'state', {
		configurable: false
		enumerable: true
		get: ->
			get(@store.getState(), @path)
	})
