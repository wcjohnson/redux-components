import applyMixin from './applyMixin'
import DynamicReducerComponent from 'redux-components/lib/DynamicReducerComponent'
import decorate from 'redux-components/lib/decorate'
import action from 'redux-components/lib/decorators/action'
import selector from 'redux-components/lib/decorators/selector'
import bind from 'redux-components/lib/decorators/bind'
import identityReducer from 'nanotools/lib/identityReducer'

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
	displayName: true
}

class LegacyReduxComponent extends DynamicReducerComponent
	constructor: ->
		super()

	getReducer: -> identityReducer

	updateReducer: ->
		nextReducer = @getReducer(@state)
		@__internalReducer = nextReducer

setPrototypeProperty = (clazz, k, v) ->
	if clazz.prototype.hasOwnProperty(k)
		throw new Error("Duplicate key `#{k}` defined in `createClass` specification for class named `#{clazz.spec.displayName}`")

	clazz.prototype[k] = v
	return

export default createClass = (spec) ->
	# Apply default mixin, then setup the spec
	newSpec = { applyMixin }
	newSpec.applyMixin(newSpec, spec)
	# Legacy redux-components contract: updateReducer() is applied after all other stuff.
	newSpec.applyMixin(newSpec, {
		componentWillMount: -> @updateReducer()
	})

	class SpecifiedReduxComponent extends LegacyReduxComponent
		constructor: ->
			super()

	# inherit from ReduxComponent
	SpecifiedReduxComponent.spec = spec
	# Apply displayName
	if spec.displayName
		Object.defineProperty(SpecifiedReduxComponent, 'name', { value: spec.displayName })
	# Apply spec to prototype, statics to constructor
	for own k,v of newSpec when (not dontPrototypeThese[k])
		setPrototypeProperty(SpecifiedReduxComponent, k, v)
		if (typeof v is 'function') and (not dontBindThese[k])
			decorate(SpecifiedReduxComponent, { "#{k}": bind })
	for own k,v of (newSpec.statics or {})
		SpecifiedReduxComponent[k] = v

	# 0.4.0: ES classes: move static properties onto the constructor
	if newSpec.verbs
		SpecifiedReduxComponent.verbs = newSpec.verbs
	for k,v of newSpec.actionCreators or {}
		setPrototypeProperty(SpecifiedReduxComponent, k, v)
		decorate(SpecifiedReduxComponent, { "#{k}": action() } )
	for k,v of newSpec.actionDispatchers or {}
		setPrototypeProperty(SpecifiedReduxComponent, k, v)
		decorate(SpecifiedReduxComponent, { "#{k}": action({isDispatcher: true}) } )
	for k,v of newSpec.selectors or {}
		setPrototypeProperty(SpecifiedReduxComponent, k, v)
		decorate(SpecifiedReduxComponent, { "#{k}": selector({isObservable: true}) } )

	SpecifiedReduxComponent
