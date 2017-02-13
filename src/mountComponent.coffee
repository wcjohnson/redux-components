export willMountComponent = (store, componentInstance, path) ->
	componentInstance.__manualMount = true
	componentInstance.__willMount(store, path, null)
	componentInstance.reducer

export didMountComponent = (componentInstance) ->
	componentInstance.__didMount()

export willUnmountComponent = (componentInstance) ->
	componentInstance.__willUnmount()

export mountRootComponent = (store, componentInstance) ->
	reducer = willMountComponent(store, componentInstance, [])
	store.replaceReducer(reducer)
	didMountComponent(componentInstance)
