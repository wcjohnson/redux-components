"use strict"

{ get } = require './util'
slice = [].slice

scopeSelector = (sel, self) -> ->
	fwdArgs = slice.call(arguments)
	fwdArgs[0] = self.state
	sel.apply(self, fwdArgs)

DefaultMixin = {
	componentWillMount: ->
		store = @store; myPath = @path

		## Scope the bits that need scoping.
		# Scope @state
		Object.defineProperty(@, 'state', { configurable: false, enumerable: true, get: -> get( store.getState(), myPath ) })
		# Scope verbs
		if @verbs
			stringPath = myPath.join('.')
			(@[verb] = "#{stringPath}:#{verb}") for verb in @verbs
		# Bind action creators
		if @actionCreators
			(@[acKey] = ac.bind(@)) for acKey, ac of @actionCreators
		# Scope selectors
		if @selectors
			(@[selKey] = scopeSelector(sel, @)) for selKey, sel of @selectors

		# Make sure coffeescript doesn't generate an extra array here.
		undefined
}

module.exports = DefaultMixin
