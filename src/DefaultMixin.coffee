import { get } from './util'


# DefaultMixin is mixed into all component specs automatically by createClass.
export default DefaultMixin = {
	componentWillMount: ->
		store = @store; myPath = @path

		## Path-dependent initialization
		# Scope @state
		Object.defineProperty(@, 'state', { configurable: false, enumerable: true, get: -> get( store.getState(), myPath ) })

		# Scope verbs
		if @verbs
			stringPath = @path.join('.')
			(@[verb] = "#{stringPath}:#{verb}") for verb in @verbs

		undefined

	componentDidMount: ->
		# If any observers were deferred, apply them now that we are mounted.
		if @__deferObservedSelectors
			for selector in @__deferObservedSelectors
				selector.__isBeingObserved(true)
			delete @__deferObservedSelectors

		undefined
}
