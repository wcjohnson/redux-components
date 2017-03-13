import { chain } from './util'
import invariant from 'invariant'
import ReduxComponent from './ReduxComponent'

# Handle various special mixin keys
chainedKeyHandler = (spec, mixin, key, val) ->
	invariant(typeof(val) is 'function', "mixin key `#{key}` must be a function")
	if spec[key]
		spec[key] = chain(spec[key], val)
	else
		spec[key] = val

concatKeyHandler = (spec, mixin, key, val) ->
	if not spec[key] then spec[key] = []
	spec[key] = spec[key].concat(val)

assignKeyHandler = (spec, mixin, key, val) ->
	invariant(typeof(val) is 'object', "mixin key `#{key}` must be an object")
	spec[key] = Object.assign(spec[key] or {}, val)

bannedKeyHandler = (spec, mixin, key, val) ->
	invariant(false, "mixin key `#{key}` would shadow a documented key on the ReduxComponent instance, and is therefore forbidden")

applyMixinKeyHandler = (spec, mixin, key, val) ->
	spec.applyMixin(spec, mixin) for mixin in val
	undefined

# Table of special specification keys and how to handle them when encountered.
mixinKeyHandlers = {
	# Mixins can change how future mixins get applied. Duuuuuude.
	applyMixin: chainedKeyHandler
	# Mixins get applied to the spec. Mixins can themselves have mixins, which are applied to the spec, after the current mixin, as if they were on the spec itself.
	mixins: applyMixinKeyHandler
	# Statics are assigned
	statics: assignKeyHandler
	# Lifecycle methods are chained.
	componentWillMount: chainedKeyHandler
	componentDidMount: chainedKeyHandler
	componentWillUnmount: chainedKeyHandler
	# getReducer: enforce function, uniqueness.
	getReducer: (spec, mixin, key, val) ->
		invariant(typeof(val) is 'function', "mixin key `#{key}` must be a function")
		spec[key] = val
	# verbs: concatenate arrays
	verbs: concatKeyHandler
	# actionCreators, actions, selectors: assign
	actionCreators: assignKeyHandler
	actionDispatchers: assignKeyHandler
	actions: assignKeyHandler
	selectors: assignKeyHandler
	# Prevent mixins from shadowing stuff
	state: bannedKeyHandler
	store: bannedKeyHandler
	parentComponent: bannedKeyHandler
	path: bannedKeyHandler
	reducer: bannedKeyHandler
}

export default baseApplyMixin = (spec, mixin) ->
	# Allow the use of ReduxComponentClasses as mixins
	if mixin?.prototype and (mixin.prototype instanceof ReduxComponent)
		mixin = mixin.prototype.__spec
	# Force mixin of submixins to happen before everything else.
	if mixin.mixins then mixinKeyHandlers.mixins(spec, mixin, 'mixins', mixin.mixins)
	# Apply this mixin
	for own key, val of mixin
		if key isnt 'mixins'
			if (handler = mixinKeyHandlers[key])
				handler(spec, mixin, key, val)
			else
				spec[key] = val
	# Don't let coffeescript make a comprehension here
	undefined
