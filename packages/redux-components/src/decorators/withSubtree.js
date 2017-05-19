import identityReducer from 'nanotools/lib/identityReducer'
import createSubtreeLifecycleMethods from '../util/createSubtreeLifecycleMethods'

export default function withSubtree(getSubtree) {
	return Clazz => class extends Clazz {
		constructor(...args) {
			super(...args)

			this.__subtreeReducer = identityReducer
			Object.assign(this, createSubtreeLifecycleMethods(getSubtree, super.componentWillMount, super.componentDidMount, super.componentWillUnmount))
		}

		__notifyChildren(state) {
			if(this.__subtreeKeys) {
				var keys = this.__subtreeKeys
				for(var i = 0, len = keys.length; i < len; i++) {
					this[keys[i]].getSubject().next(state)
				}
			}
		}

		reducer(state, action) {
			var superReducer = super.reducer
			var nextState = state
			// Merge subtree state only if it changes.
			var nextSubtreeState = this.__subtreeReducer(state, action)
			if (nextSubtreeState !== state) {
				nextState = Object.assign({}, state, nextSubtreeState)
			}
			// Call superclass reducer.
			return superReducer.call(this, nextState, action)
		}
	}
}
