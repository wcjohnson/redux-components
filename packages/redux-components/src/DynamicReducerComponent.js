import ReduxComponent from './ReduxComponent'
import identityReducer from 'nanotools/lib/identityReducer'
import invariant from 'nanotools/lib/invariant'

function indirectReducer(state, action) {
	return this.__internalReducer(state, action)
}

export default class DynamicReducerComponent extends ReduxComponent {
	constructor() {
		super()
		// Initial reducer is as defined on the class body.
		if(this.reducer) {
			this.__internalReducer = this.reducer;
		} else {
			this.__internalReducer = identityReducer;
		}
		// Replace reducer with a layer of indirection
		this.reducer = indirectReducer.bind(this)
	}

	// Imitate the Redux API
	replaceReducer(nextReducer) {
		/* eslint-disable no-undef */
		if (process.env.NODE_ENV !== 'production') {
			/* eslint-enable no-undef */
			invariant(typeof nextReducer === 'function', `DynamicReducerComponent of type ${this.displayName} (mounted at location ${this.path}) is replacing its reducer with a non-function.`)
		}

		this.__internalReducer = nextReducer

		// The Redux API sends some junk action to a new reducer when store.replaceReducer is called.
		// We will do the same.
		if(this.isMounted()) {
			this.store.dispatch({ type: '@@redux-components/INIT' })
		}
	}
}
