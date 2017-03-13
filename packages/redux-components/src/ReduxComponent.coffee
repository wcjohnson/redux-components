import invariant from 'invariant'
import { get, nullIdentity } from './util'
import $$observable from 'symbol-observable'
import makeSelectorObservable from './makeSelectorObservable'

slice = [].slice

################################
# Component prototype
export default ReduxComponent = ( -> )

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

ReduxComponent.prototype.__init = ->
	@reducer = indirectReducer.bind(@)
	@__internalReducer = nullIdentity

	# Bind action creators
	if @actionCreators
		(@[key] = func.bind(@)) for key, func of @actionCreators
	# Bind actions
	if @actionDispatchers
		(@[key] = dispatchAction(func, @)) for key, func of @actionDispatchers
	# Scope selectors
	if @selectors
		for key, func of @selectors
			scoped = scopeSelector(func, @)
			@[key] = makeSelectorObservable(@, scoped)

	undefined

ReduxComponent.prototype.updateReducer = ->
	# XXX: should we invariant() that the reducer is an actual reducer?
	if process.env.NODE_ENV isnt 'production'
		invariant(typeof @getReducer is 'function', "redux-component of type #{@displayName} (mounted at location #{@path}) is updating its reducer, but does not have a getReducer() method.")
	@__internalReducer = @getReducer(@state)
	undefined

ReduxComponent.prototype.__willMount = (@store, @path = [], @parentComponent = null) ->
	invariant(not @__mounted, "redux-component of type #{@displayName} was multiply initialized. This can indicate a cycle in your component graph, which is illegal. Make sure each instance is only used once in your tree. If you wish to use a component in multiple places, construct additional instances.")
	@componentWillMount?()
	#@reducer = indirectReducer.bind(@)
	@updateReducer()
	undefined

ReduxComponent.prototype.__didMount = ->
	@__mounted = true
	@componentDidMount?()
	undefined

ReduxComponent.prototype.__willUnmount = ->
	invariant(@__mounted, "redux-component of type #{@displayName} was unmounted when not mounted. This can indicate an issue in a dynamic reducer component such as redux-components-map.")
	@componentWillUnmount?()
	@__internalReducer = nullIdentity
	delete @__mounted

ReduxComponent.prototype.isMounted = -> @__mounted?
