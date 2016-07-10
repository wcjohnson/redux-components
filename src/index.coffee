#
# Component architecture for redux
#
"use strict"

{ combineReducers } = require 'redux'

# Utilities
assign = (dst, src) -> (if src.hasOwnProperty(k) then dst[k] = src[k]) for k of src; dst
chain = (one, two) -> -> one.apply(@, arguments); two.apply(@, arguments)
get = (object, path) ->
	index = 0; length = path.length
	while object? and index < length
		object = object[path[index++]]
	if (index is length) then object else undefined

# Constants related to mixins
bannedMixinKeys = {
	getShape: true, mixins: true, reducer: true, verbs: true, actionCreators: true, selectors: true
	rawSelectors: true, store: true, parentComponent: true, parentKey: true, path: true
	shape: true, displayName: true, rawVerbs: true, componentDidMount: true, statics: true
}
assignedMixinKeys = { actionCreators: true, selectors: true, rawSelectors: true, statics: true }
arrayMixinKeys = { verbs: true, rawVerbs: true }
chainedMixinKeys = { componentDidMount: true }

localizeSelector = (sel, self) ->
	(state) ->
		# XXX: should we have a dev mode invariant here to check if the ReduxComponent has been mounted in
		# the state tree? (check for __initialized)
		sel.call(self, self.getLocalState())

################################
# Component prototype
ReduxComponent = ( -> )

ReduxComponent.prototype.initialize = (@store, @parentComponent, @parentKey) ->
	# Initialization check
	if @__initialized
		throw new Error("redux-component of type #{@constructor.displayName} was multiply initialized. This usually indicates a cycle in your component graph, which is illegal. Make sure each instance is only used once in your tree. If you wish to use a component in multiple places, construct additional instances.")
	@__initialized = true

	store = @store; parentComponent = @parentComponent; parentKey = @parentKey

	# Create path to this component. (Must be done before initialize on subcomponents.)
	@path = parentComponent?.path or []; if parentKey then @path = @path.concat([parentKey])
	myPath = @path

	# Create path-dependent stuff
	if parentComponent
		if not parentComponent.shape then parentComponent.shape = {}
		parentComponent.shape[parentKey] = @
		@getLocalState = -> (parentComponent.getLocalState())[parentKey]
	else
		@getLocalState = -> store.getState()

	# Create local @state getter
	Object.defineProperty(@, 'state', {
		configurable: false, enumerable: true
		get: -> get( store.getState(), myPath )
	})

	# Construct reducer from shape
	if @getShape
		# Compute the state shape
		shape = @getShape()
		for own k,subcomponent of shape
			# Initialize reducer-parts that are typed subcomponents
			if subcomponent instanceof ReduxComponent
				# Run initializer
				subcomponent.initialize(@store, @, k)
				# Store reducer
				shape[k] = subcomponent.reducer
		# We have a table of reducers; combine them
		@reducer = combineReducers(shape)

	# Install default reducer if needed
	# XXX: should an empty reducer be considered an invariant violation?
	if typeof(@reducer) isnt 'function' then @reducer = ( (x) -> x )
	@reducer = @reducer.bind(@)

	# Create verbs
	verbs = @verbs; @verbs = {}
	if verbs
		stringPath = @path.join('.')
		(@verbs[k] = "#{stringPath}:#{k}") for k in verbs
	if @rawVerbs then (@verbs[k] = "#{k}") for k in @rawVerbs

	# Return the reducer
	@reducer

################################
# Mixin support
mixIntoSpec = (spec, mixin) ->
	# Merge getShape functions.
	if typeof(mixin.getShape) is 'function'
		prior = spec.getShape or ( -> {} )
		spec.getShape = -> assign( prior.call(@), mixin.getShape.call(@) )

	# Assign mixin keys to spec
	for k of assignedMixinKeys
		if mixin[k]
			spec[k] = assign( spec[k] or {}, mixin[k] )
	for k of arrayMixinKeys
		if mixin[k]
			if not spec[k] then spec[k] = []
			spec[k] = spec[k].concat(mixin[k])
	for k of chainedMixinKeys
		if mixin[k]
			if not spec[k] then spec[k] = mixin[k] else spec[k] = chain(spec[k], mixin[k])

	# Merge other functions
	for k,v of mixin
		if not bannedMixinKeys[k] then spec[k] = v

	null

################################
# Main function
createClass = (spec) ->
	# Do mixins
	if spec.mixins then	(mixIntoSpec(spec, mixin) for mixin in spec.mixins)

	if spec.getShape and spec.reducer
		throw new Error("redux-components may either have getShape or a reducer, not both. consider breaking your component up into smaller pieces. if your mixins use subcomponents, factor your custom reducer into yet another subcomponent.")

	Constructor = ->
		# Auto-call constructor
		if not (this instanceof Constructor) then return new Constructor()
		# Perform auto-binding of action creators and selectors.
		actionCreators = {}
		(actionCreators[k] = ac.bind(@)) for k,ac of (@actionCreators or {})
		@actionCreators = actionCreators

		combinedSelectors = {}

		(combinedSelectors[k] = sel.bind(@)) for k,sel of (@rawSelectors or {})
		(combinedSelectors[k] = localizeSelector(sel, @)) for k,sel of (@selectors or {})
		@selectors = combinedSelectors

		# XXX: Can we get rid of spec here? we could probably garbage collect most of the specs if we could.
		(@[k] = f.bind(@)) for k,f of spec when ( (typeof(f) is 'function') and (not bannedMixinKeys[k]) )

		# coffeescript...
		@

	Constructor.prototype = new ReduxComponent
	Constructor.prototype.constructor = Constructor

	for k,v of spec
		Constructor.prototype[k] = v
	for k,v of (spec.statics or {})
		Constructor[k] = v

	Constructor

traverseSubtreePreorder = (comp, callback) ->
	callback(comp)
	if comp.shape then callback(subcomp) for k,subcomp of comp.shape when (subcomp instanceof ReduxComponent)
	undefined

connectStoreToRootComponent = (store, comp) ->
	reducer = comp.initialize(store)
	store.replaceReducer(reducer)
	# Mount components in order.
	traverseSubtreePreorder(comp, (x) -> x.componentDidMount?() )

module.exports = { createClass, connectStoreToRootComponent }
