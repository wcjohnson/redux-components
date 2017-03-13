import { get } from './util'


# DefaultMixin is mixed into all component specs automatically by createClass.
export default DefaultMixin = {
	componentDidMount: ->
		# If any observers were deferred, apply them now that we are mounted.
		if @__deferObservedSelectors
			for selector in @__deferObservedSelectors
				selector.__isBeingObserved(true)
			delete @__deferObservedSelectors

		undefined
}
