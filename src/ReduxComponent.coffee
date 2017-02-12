import invariant from 'invariant'
import { get, nullIdentity } from './util'
import $$observable from 'symbol-observable'

################################
# Component prototype
export default ReduxComponent = ( -> )

indirectReducer = (state, action) ->
	@__internalReducer.call(@, state, action)

ReduxComponent.prototype.__init = ->
	@reducer = indirectReducer.bind(@)
	@__internalReducer = nullIdentity
	undefined

ReduxComponent.prototype.updateReducer = ->
	# XXX: should we invariant() that the reducer is an actual reducer?
	if process.env.NODE_ENV isnt 'production'
		invariant(typeof @getReducer is 'function', "redux-component of type #{@displayName} (mounted at location #{@path}) is updating its reducer, but does not have a getReducer() method.")
	@__internalReducer = @getReducer(@state)

ReduxComponent.prototype.__willMount = (@store, @path = [], @parentComponent = null) ->
	invariant(not @__mounted, "redux-component of type #{@displayName} was multiply initialized. This can indicate a cycle in your component graph, which is illegal. Make sure each instance is only used once in your tree. If you wish to use a component in multiple places, construct additional instances.")
	@__mounted = true
	@componentWillMount?()
	#@reducer = indirectReducer.bind(@)
	@updateReducer()

ReduxComponent.prototype.__willUnmount = ->
	invariant(@__mounted, "redux-component of type #{@displayName} was unmounted when not mounted. This can indicate an issue in a dynamic reducer component such as redux-components-map.")
	@componentWillUnmount?()
	@__internalReducer = nullIdentity
	delete @__mounted
