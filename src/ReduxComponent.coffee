import invariant from 'invariant'
import { get, nullIdentity } from './util'
import $$observable from 'symbol-observable'

indirectReducer = (state, action) ->
	@state = @__internalReducer.call(@, state, action)

################################
# Component prototype
export default ReduxComponent = ( -> )

ReduxComponent.prototype.__init = ->
	@reducer = indirectReducer.bind(@)
	@__internalReducer = nullIdentity
	undefined

ReduxComponent.prototype.updateReducer = ->
	# XXX: should we invariant() that the reducer is an actual reducer?
	@__internalReducer = @getReducer(@state)

ReduxComponent.prototype.__willMount = (@store, @path = [], @parentComponent = null) ->
	invariant(not @__mounted, "redux-component of type #{@constructor.displayName} was multiply initialized. This can indicate a cycle in your component graph, which is illegal. Make sure each instance is only used once in your tree. If you wish to use a component in multiple places, construct additional instances.")
	@__mounted = true

	# Get initial state from store.
	@state = get(@store.getState(), @path)

	@componentWillMount?()
	@updateReducer()
