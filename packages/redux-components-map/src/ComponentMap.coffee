import { createClass, createComponent } from 'redux-components-legacy'
import combineReducers from './combineReducers'

metadataSymbol = '@@metadata'

nullifier = (x) -> if x is undefined then null else x

export default ComponentMap = (typeMap) ->
	# Support objects as typemaps
	if typeof(typeMap) isnt 'function'
		typeMapObject = typeMap
		typeMap = (key) -> typeMapObject[key]

	createClass {
		displayName: 'ComponentMap'
		verbs: [ 'COMPONENT_MAP_ADD', 'COMPONENT_MAP_REMOVE', 'COMPONENT_MAP_BULK' ]

		selectors: {
			metadata: (state) -> state?[metadataSymbol]
		}

		# Portion of the reducer dealing with metadata.
		__metadataReducer: (state = {}, action) ->
			switch action.type
				when @COMPONENT_MAP_ADD
					Object.assign({}, state, { "#{action.payload.key}": action.payload.descriptor })
				when @COMPONENT_MAP_REMOVE
					nextState = Object.assign({}, state)
					delete nextState[action.payload]
					nextState
				when @COMPONENT_MAP_BULK
					nextState = Object.assign({}, state)
					delete nextState[k] for k of action.payload.remove if action.payload.remove
					nextState[k] = v for k,v of action.payload.add if action.payload.add
					nextState
				else
					state

		combineReducers: ->
			@__internalReducer = combineReducers(@reducerMap)
			undefined

		componentWillMount: ->
			# Initialize internal data structures
			@reducerMap = Object.create(null)
			@reducerMap[metadataSymbol] = @__metadataReducer
			@componentMap = Object.create(null)
			# Make initial reducer
			@combineReducers()

		componentDidMount: ->
			# Diff whenever metadata changes.
			@subscription = @metadata.subscribe({
				next: => @diff()
			})
			# Mount components from preMount instructions.
			if @__preMountMap
				@bulk(@__preMountMap)
				delete @__preMountMap

		componentWillUnmount: ->
			# Unsubscribe from stuff
			@subscription?.unsubscribe?()
			delete @subscription
			# Unmount subcomponents
			component.__willUnmount() for component in @componentMap
			# Replace with identity reducer
			@__internalReducer = nullifier
			# Abandon references to unmounted components.
			delete @componentMap

		# Diff algorithm to produce dynamic reducers.
		diff: ->
			if @__reentrancyGuard
				throw new Error("Reentrant modification of a ComponentMap instance was detected.")
			@__reentrancyGuard = true
			# Early out if our component has no state yet.
			metadata = @state?[metadataSymbol]
			if not metadata then return
			# Step 1: Determine which components were removed or added.
			removed = (k for k of @componentMap when (not (k of metadata)) and (k isnt metadataSymbol))
			added = (k for k of metadata when (not (k of @componentMap)) and (k isnt metadataSymbol))
			# Step 2:
			# Mount a *temporary* reducer using `combineReducers()` but with the nullifier function attached at each `added` node.
			# We only need the temporary reducer if some nodes were removed.
			# Don't delete the `removed` nodes from the state tree yet, because we haven't called `willUnmount` on them.
			if (added.length > 0) and (removed.length > 0)
				@reducerMap[k] = nullifier for k in added
				@combineReducers()
			# Step 3: Run `componentWillUnmount` for each `removed` node that is a ReduxComponent.
			@componentMap[k].__willUnmount() for k in removed
			# Step 4: Remove deleted nodes from the internal data structures
			if removed.length > 0
				delete @reducerMap[k]; delete @componentMap[k] for k in removed
			# Step 5: Instantiate the added components
			for k in added
				componentDescriptor = typeMap(metadata[k])
				if not componentDescriptor
					throw new Error("typeMap entry not found for ComponentMap entry with key `#{k}`")
				@componentMap[k] = createComponent(componentDescriptor)
			# Step 6: willMount the added components
			for k in added
				nextPath = @path.slice()
				nextPath.push(k)
				@componentMap[k].__willMount(@store, nextPath, @)
			# Step 7: Build the "real" reducer out of the reducers of all the components that now exist.
			@reducerMap[k] = component.reducer for k, component of @componentMap
			@combineReducers()
			# Step 8: dispatch a nonce action causing the state tree to renormalize
			if added.length > 0
				@store.dispatch({type: '@@redux-components/INIT'})
			# Step 9: Run didMount on the added components
			@componentMap[k].__didMount() for k in added
			delete @__reentrancyGuard
			# Suppress implicit return of comprehension
			undefined

		# The getReducer logic is actually handled by diff.
		getReducer: (stateNow) -> @__internalReducer or nullifier

		# API: add a key to the map
		add: (key, descriptor) ->
			if not key? then throw new Error("key must be provided")
			if @isMounted()
				if key of @componentMap then throw new Error("duplicate key `#{key}` in ComponentMap")
				@store.dispatch({ type: @COMPONENT_MAP_ADD, payload: { key, descriptor } })
			else
				if not @__preMountMap? then @__preMountMap = {}
				@__preMountMap[key] = descriptor
				undefined

		# API: remove key from map
		remove: (key) ->
			if not key? then throw new Error("key must be provided")
			if @isMounted()
				@store.dispatch({ type: @COMPONENT_MAP_REMOVE, payload: key })
			else
				if @__preMountMap? then delete @__preMountMap[key]
				undefined

		actionDispatchers: {
			bulk: (add, remove) -> { type: @COMPONENT_MAP_BULK, payload: { add, remove } }
		}

		# API: get component at key from the map.
		get: (key) -> @componentMap[key]
		# API: get keys of map.
		keys: -> Object.keys(@componentMap)
	}
