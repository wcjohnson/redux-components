import identityReducer from 'nanotools/lib/identityReducer'
import createSubtreeLifecycleMethods from '../util/createSubtreeLifecycleMethods'

export default function withSubtree(getSubtree) {
	return Clazz => class extends Clazz {
		constructor(...args) {
			super(...args)
			this.__subtreeReducer = identityReducer
			Object.assign(this, createSubtreeLifecycleMethods(getSubtree, super.componentWillMount, super.componentDidMount, super.componentWillUnmount))
		}

		reducer(state, action) {
			var superReducer = super.reducer
			if (superReducer && (superReducer != identityReducer) ) {
				var nextState = Object.assign({}, state, this.__subtreeReducer(state, action))
				return superReducer(nextState, action)
			} else {
				// Save an object creation in the most common case.
				return this.__subtreeReducer(state, action)
			}
		}
	}
}
