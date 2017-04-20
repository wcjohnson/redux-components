import { combineReducers } from 'redux'
import invariant from 'nanotools/lib/invariant'
import ReduxComponent from 'redux-components/lib/ReduxComponent'
import { willMountComponent, didMountComponent, willUnmountComponent } from 'redux-components/lib/mountComponent'
import createClass from './createClass'
import upstreamCreateComponent from 'redux-components/lib/createComponent'
import createSubtreeLifecycleMethods from 'redux-components/lib/util/createSubtreeLifecycleMethods'

##### SubtreeMixin
export SubtreeMixin = {
	getReducer: -> @__subtreeReducer

	componentWillMount: ->
		# Sanity check that our component supports subtrees
		if process.env.NODE_ENV isnt 'production'
			invariant(typeof @getSubtree is 'function', "redux-component of type #{@displayName} (mounted at location #{@path}) is using SubtreeMixin, but does not have a getSubtree() method.")

		# Delegate to redux-components internal methods
		lifecycle = createSubtreeLifecycleMethods(@getSubtree, null, null, () => this.__originalUnmount())
		@__subtreeDidMount = lifecycle.componentDidMount

		# Rework the unmount method to honor the lifecycle contract
		@__originalUnmount = this.componentWillUnmount
		actualUnmount = lifecycle.componentWillUnmount
		this.componentWillUnmount = =>
			actualUnmount.call(this)
			this.componentWillUnmount = @__originalUnmount
			delete @__subtreeDidMount
			delete @__originalUnmount

		# Call new willMount
		lifecycle.componentWillMount.call(this)
		# COMPAT: allow subtreeReducer to be accessed more directly
		this.subtreeReducer = this.__subtreeReducer

	componentDidMount: ->
		@__subtreeDidMount?()
		return
}

##### createComponent
export createComponent = upstreamCreateComponent
