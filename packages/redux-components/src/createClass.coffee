import applyMixin from './applyMixin'
import DefaultMixin from './DefaultMixin'
import ReduxComponent from './ReduxComponent'

dontBindThese = {
	state: true
	applyMixin: true
	updateReducer: true
	isMounted: true
	componentWillMount: true
	componentDidMount: true
	componentWillUnmount: true
	getReducer: true
	reducer: true
	__willMount: true
	__willUnmount: true
	__didMount: true
	__init: true
	__internalReducer: true
}

dontPrototypeThese = {
	verbs: true
	actionCreators: true
	actionDispatchers: true
	selectors: true
}

export default createClass = (spec) ->
	# Apply default mixin, then setup the spec
	newSpec = { applyMixin }
	newSpec.applyMixin(newSpec, DefaultMixin)
	newSpec.applyMixin(newSpec, spec)

	SpecifiedReduxComponent = ->
		# Allow Class() instead of new Class() if desired.
		if not (@ instanceof SpecifiedReduxComponent) then return new SpecifiedReduxComponent()
		# Call ReduxComponent constructor first
		ReduxComponent.call(@)
		# Constructor must return this.
		@

	# inherit from ReduxComponent
	SpecifiedReduxComponent.prototype = new ReduxComponent
	SpecifiedReduxComponent.prototype.constructor = SpecifiedReduxComponent
	SpecifiedReduxComponent.prototype.__spec = spec
	# Apply spec to prototype, statics to constructor
	for own k,v of newSpec when (not dontPrototypeThese[k])
		SpecifiedReduxComponent.prototype[k] = v
	for own k,v of (newSpec.statics or {})
		SpecifiedReduxComponent[k] = v

	# 0.4.0: ES classes: move static properties onto the constructor
	if newSpec.verbs
		SpecifiedReduxComponent.verbs = newSpec.verbs
	for meldKey in ['actionCreators', 'actionDispatchers', 'selectors']
		SpecifiedReduxComponent[meldKey] = []
		if newSpec[meldKey]
			for k,v of newSpec[meldKey]
				SpecifiedReduxComponent.prototype[k] = v
				SpecifiedReduxComponent[meldKey].push(k)
	SpecifiedReduxComponent.magicBind = []
	for k of SpecifiedReduxComponent.prototype
		if not dontBindThese[k]
			if typeof(SpecifiedReduxComponent.prototype[k]) is 'function'
				SpecifiedReduxComponent.magicBind.push(k)

	SpecifiedReduxComponent
