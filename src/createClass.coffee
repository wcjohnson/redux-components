import applyMixin from './applyMixin'
import DefaultMixin from './DefaultMixin'
import ReduxComponent from './ReduxComponent'

dontBindThese = {
	applyMixin: true
	updateReducer: true
	__willMount: true
	__willUnmount: true
	__mounter: true
	__init: true
}

export default createClass = (spec) ->
	# Apply default mixin, then setup the spec
	newSpec = { applyMixin }
	newSpec.applyMixin(newSpec, DefaultMixin)
	newSpec.applyMixin(newSpec, spec)

	Constructor = ->
		# Allow Class() instead of new Class() if desired.
		if not (@ instanceof Constructor) then return new Constructor()
		# Call prototype init
		@__init()
		# Magic bind all the functions on the prototype
		(@[k] = f.bind(@)) for k,f of Constructor.prototype when typeof(f) is 'function' and (not dontBindThese[k])
		# Constructor must return this.
		@

	# inherit from ReduxComponent
	Constructor.prototype = new ReduxComponent
	Constructor.prototype.constructor = Constructor
	Constructor.prototype.__spec = spec
	# Apply spec to prototype, statics to constructor
	for own k,v of newSpec
		Constructor.prototype[k] = v
	for own k,v of (newSpec.statics or {})
		Constructor[k] = v

	Constructor
