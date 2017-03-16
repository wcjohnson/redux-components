import invariant from 'nanotools/lib/invariant'
import combineReducers from 'nanotools/lib/combineReducers'
import { didMountComponent, willUnmountComponent } from '../mountComponent'
import createComponent from '../createComponent'
import identityReducer from 'nanotools/lib/identityReducer'

export default function createSubtreeLifecycleMethods(getSubtree, cWM, cDM, cWU) {
	return {
		componentWillMount() {
			var subtreeDefinition = getSubtree.call(this)
			var subtreeKeys = Object.keys(subtreeDefinition)
			var reducerMap = {}
			// Remember the keys for later unmounting.
			this.__subtreeKeys = subtreeKeys

			// Create and invoke willMount for each subcomponent
			subtreeKeys.forEach( k => {
				// Verify this won't shadow something on the class.
				if(process.env.NODE_ENV !== 'production') {
					invariant(this[k] == null, `redux-component of type ${this.displayName} (mounted at location ${this.path}) has a subtree key named "${k}" that would shadow a property of the parent component.`)
				}

				// Conjure the child component
				var component = createComponent( subtreeDefinition[k] )
				this[k] = component
				component.__willMount(this.store, this.path.concat([k]), this)
				reducerMap[k] = component.reducer
			})

			// Create the combined reducer
			this.__subtreeReducer = combineReducers(reducerMap)

			// redux-components lifecycle contract requires this to be called in postorder (after children)
			if(cWM) cWM.call(this)
		},

		componentDidMount() {
			this.__subtreeKeys.forEach( k => didMountComponent(this[k]) )
			if(cDM) cDM.call(this)
		},

		componentWillUnmount() {
			this.__subtreeKeys.forEach( k => willUnmountComponent(this[k]) )
			if(cWU) cWU.call(this)
			// Remove reducers after unmount lifecycle.
			this.__subtreeReducer = identityReducer
			this.__subtreeKeys.forEach( k => delete this[k] )
			delete this.__subtreeKeys
		}
	}
}
