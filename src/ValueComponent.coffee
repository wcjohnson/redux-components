import createClass from './createClass'
import ObservableSelectorMixin from './ObservableSelectorMixin'

# A ValueComponent holds an opaque value. The only action is SET, which changes the
# value to the payload of the action.
export default ValueComponent = createClass {
	displayName: 'ValueComponent'

	mixins: [ ObservableSelectorMixin ]

	verbs: [ 'SET' ]

	getReducer: -> (state = null, action) ->
		if action.type is @SET
			# Reducer may not return undefined. Promote to null.
			if action.payload is undefined then null else action.payload
		else
			state

	selectors: {
		get: (state) -> state
	}

	actionCreators: {
		setAction: (nextValue) -> { type: @SET, payload: nextValue }
	}

	actionDispatchers: {
		set: (nextValue) -> { type: @SET, payload: nextValue }
	}
}
