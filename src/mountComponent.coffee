export mountRootComponent = (store, componentInstance) ->
	componentInstance.__willMount(store, [], null)
	store.replaceReducer(componentInstance.reducer)
	componentInstance.componentDidMount?()

export willMountComponent = (store, componentInstance, path) ->
	componentInstance.__manualMount = true
	componentInstance.__willMount(store, path, null)
	componentInstance.reducer

export didMountComponent = (componentInstance) ->
	componentInstance.componentDidMount?()

export willUnmountComponent = (componentInstance) ->
	componentInstance.__willUnmount()
