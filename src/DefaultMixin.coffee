import { get } from './util'
slice = [].slice

# Scope a selector to a component.
scopeSelector = (sel, self) -> ->
	fwdArgs = slice.call(arguments)
	fwdArgs[0] = self.state
	sel.apply(self, fwdArgs)

# Bind an action to automatically dispatch to the right store.
bindAction = (actionCreator, self) -> ->
	self.store.dispatch(actionCreator.apply(self, arguments))

# DefaultMixin is mixed into all component specs automatically by createClass.
export default DefaultMixin = {
	componentWillMount: ->
		## Scope the bits that need scoping.
		# Scope verbs
		if @verbs
			stringPath = @path.join('.')
			(@[verb] = "#{stringPath}:#{verb}") for verb in @verbs
		# Bind action creators
		if @actionCreators
			(@[acKey] = ac.bind(@)) for acKey, ac of @actionCreators
		# Bind actions
		if @actions
			(@[acKey] = bindAction(ac, @)) for acKey, ac of @actions
		# Scope selectors
		if @selectors
			(@[selKey] = scopeSelector(sel, @)) for selKey, sel of @selectors

		# Make sure coffeescript doesn't generate an extra array here.
		undefined
}
