import createBehaviorSubject from 'observable-utils/lib/createBehaviorSubject'

connectSelector = (componentInstance, selector, observer) ->
	lastSeenValue = undefined

	observeState = ->
		val = selector(componentInstance.store.getState())
		if val isnt lastSeenValue
			lastSeenValue = val; observer.next(val)

	selector.__unsubscriber = componentInstance.store.subscribe(observeState)
	observeState()

disconnectSelector = (selector) ->
	selector.__unsubscriber?()
	delete selector.__unsubscriber

# Make a selector on a ReduxComponentInstance into an ES7 Observable.
export default makeSelectorObservable = (componentInstance, selector) ->
	observerCount = 0

	# Make the selector a Subject.
	subj = createBehaviorSubject({
		onObserversChanged: (observers) ->
			observerCount = observers.length
			if observerCount is 0
				# No longer being observed
				disconnectSelector(selector)
			else if observerCount is 1 and componentInstance.isMounted()
				connectSelector(componentInstance, selector, selector)
			return
	})
	Object.assign(selector, subj)
	# When component mounts, connect selector if needed.
	selector.mount = ->
		if observerCount > 0 then connectSelector(componentInstance, selector, selector)
	# When component unmounts, unsubscribe it.
	selector.unmount = ->
		disconnectSelector(selector)

	selector
