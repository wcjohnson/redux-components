import applyMixin from './applyMixin'
import ReduxComponent from './ReduxComponent'
import decorate from './decorate'
import action from './decorators/action'
import selector from './decorators/selector'

import { inspect } from 'util'

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

	# Magic bind stuff on prototype
	SpecifiedReduxComponent.magicBind = []
	for k of SpecifiedReduxComponent.prototype
		if not dontBindThese[k]
			if typeof(SpecifiedReduxComponent.prototype[k]) is 'function'
				SpecifiedReduxComponent.magicBind.push(k)

	# 0.4.0: ES classes: move static properties onto the constructor
	if newSpec.verbs
		SpecifiedReduxComponent.verbs = newSpec.verbs
	for k,v of newSpec.actionCreators or {}
		SpecifiedReduxComponent.prototype[k] = v
		decorate(SpecifiedReduxComponent, { "#{k}": action() } )
	for k,v of newSpec.actionDispatchers or {}
		SpecifiedReduxComponent.prototype[k] = v
		decorate(SpecifiedReduxComponent, { "#{k}": action({isDispatcher: true}) } )
	for k,v of newSpec.selectors or {}
		SpecifiedReduxComponent.prototype[k] = v
		decorate(SpecifiedReduxComponent, { "#{k}": selector({isObservable: true}) } )



	console.log "afterSpec", {spec, result: inspect(SpecifiedReduxComponent) }

	SpecifiedReduxComponent
