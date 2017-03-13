import applyMixin from './applyMixin'
import DefaultMixin from './DefaultMixin'
import ReduxComponent from './ReduxComponent'

dontBindThese = {
	applyMixin: true
	updateReducer: true
	isMounted: true
	componentWillMount: true
	componentDidMount: true
	componentWillUnmount: true
	getReducer: true
	__willMount: true
	__willUnmount: true
	__didMount: true
	__init: true
}

export default createClass = (spec) ->
	# Apply default mixin, then setup the spec
	newSpec = { applyMixin }
	newSpec.applyMixin(newSpec, DefaultMixin)
	newSpec.applyMixin(newSpec, spec)

	SpecifiedReduxComponent = ->
		# Allow Class() instead of new Class() if desired.
		if not (@ instanceof SpecifiedReduxComponent) then return new SpecifiedReduxComponent()
		# Call prototype init
		@__init()
		# Magic bind all the functions on the prototype
		(@[k] = f.bind(@)) for k,f of SpecifiedReduxComponent.prototype when typeof(f) is 'function' and (not dontBindThese[k])
		# Constructor must return this.
		@

	# inherit from ReduxComponent
	SpecifiedReduxComponent.prototype = new ReduxComponent
	SpecifiedReduxComponent.prototype.constructor = SpecifiedReduxComponent
	SpecifiedReduxComponent.prototype.__spec = spec
	# Apply spec to prototype, statics to constructor
	for own k,v of newSpec
		SpecifiedReduxComponent.prototype[k] = v
	for own k,v of (newSpec.statics or {})
		SpecifiedReduxComponent[k] = v

	SpecifiedReduxComponent
