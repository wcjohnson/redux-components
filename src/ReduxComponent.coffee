"use strict"
_export = null

invariant = require 'inv'

################################
# Component prototype
ReduxComponent = ( -> )

ReduxComponent.prototype.__willMount = (@store, @path = [], @parentComponent = null) ->
	invariant(not @__mounted, "redux-component of type #{@constructor.displayName} was multiply initialized. This can indicate a cycle in your component graph, which is illegal. Make sure each instance is only used once in your tree. If you wish to use a component in multiple places, construct additional instances.")
	@__mounted = true

	@componentWillMount?()
	# XXX: should we invariant() that the reducer is an actual reducer?
	@reducer = @getReducer().bind(@)

_export = ReduxComponent
module.exports = _export
