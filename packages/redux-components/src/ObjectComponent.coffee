import createClass from './createClass'
import ObservableSelectorMixin from './ObservableSelectorMixin'

shallowEqual = (a, b) ->
	for key of a
		if (not(key of b)) or (a[key] isnt b[key]) then return false
	for key of b
		if (not(key of a)) or (b[key] isnt a[key]) then return false
	true

# An ObjectComponent holds a single object with opaque values. The actions are SET
# and MERGE.
export default ObjectComponent = createClass {
	displayName: 'ObjectComponent'

	mixins: [ ObservableSelectorMixin ]

	verbs: [ 'SET', 'MERGE' ]

	getReducer: -> (state = {}, action) ->
		switch action.type
			when @SET
				if shallowEqual(state, action.payload) then state else Object.assign({}, action.payload)
			when @MERGE
				maybeNextState = Object.assign({}, state, action.payload)
				if shallowEqual(state, maybeNextState) then state else maybeNextState
			else
				state

	selectors: {
		get: (state) -> state
	}

	actionCreators: {
		setAction: (nextValue) -> { type: @SET, payload: nextValue }
		mergeAction: (nextValue) -> { type: @MERGE, payload: nextValue }
	}

	actionDispatchers: {
		set: (nextValue) -> { type: @SET, payload: nextValue }
		merge: (nextValue) -> { type: @MERGE, payload: nextValue }
	}
}
