"use strict"

defaultMounter = (store, componentInstance) ->
	store.replaceReducer(componentInstance.reducer)

mountComponent = (store, componentInstance, path = [], mounter = defaultMounter) ->
	componentInstance.__mounter = mounter
	componentInstance.__willMount(store, path, null)
	mounter?(store, componentInstance)
	componentInstance.componentDidMount?()

module.exports = mountComponent
