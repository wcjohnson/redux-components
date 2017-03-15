import createBehaviorSubject from 'observable-utils/lib/createBehaviorSubject'

# Make a selector on a ReduxComponentInstance into an ES7 Observable.
export default makeSelectorObservable = (componentInstance, selector) ->
	observerCount = 0
	subscription = undefined
	lastSeenValue = undefined

	# Make the selector a Subject.
	subj = createBehaviorSubject({
		onObserversChanged: (observers) ->
			observerCount = observers.length
			if observerCount is 0
				# No subscribers left; remove upstream subscription.
				subscription?.unsubscribe?()
				subscription = undefined
			else if observerCount is 1

				# This closure will observe and select from the store.
				# Selectors expect to receive valid states, not undefined, so only call
				# the selector when the state is fully realized.
				observeState = ->
					if not componentInstance.store then return
					state = componentInstance.store.getState()
					if state isnt undefined
						val = selector(state)
						if val isnt lastSeenValue then lastSeenValue = val; subj.next(val)

				subscription = componentInstance.__getSubject().subscribe({ next: observeState })
				observeState()
			return
	})
	Object.assign(selector, subj)

	selector
