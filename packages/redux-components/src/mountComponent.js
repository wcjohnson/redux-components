export function willMountComponent(store, componentInstance, path) {
	componentInstance.__manualMount = true
	componentInstance.__willMount(store, path, null)
	return componentInstance.reducer
}

export function didMountComponent(componentInstance) {
	componentInstance.__didMount()
}

export function willUnmountComponent(componentInstance) {
	componentInstance.__willUnmount()
}

export function mountRootComponent(store, componentInstance) {
	var reducer = willMountComponent(store, componentInstance, [])
	store.replaceReducer(reducer)
	didMountComponent(componentInstance)
}
