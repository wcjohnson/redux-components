defaultMounter = (store, componentInstance) ->
	store.replaceReducer(componentInstance.reducer)

export default mountComponent = (store, componentInstance, path = [], mounter = defaultMounter) ->
	componentInstance.__mounter = mounter
	componentInstance.__willMount(store, path, null)
	mounter?(store, componentInstance)
	componentInstance.componentDidMount?()
