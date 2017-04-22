import createBehaviorSubject from 'observable-utils/lib/createBehaviorSubject'

// Make a selector on a ReduxComponentInstance into an ES7 Observable.
export default function makeSelectorObservable(componentInstance, selector) {
	var observerCount = 0
	var subscription = undefined
	var lastSeenValue = undefined

	// Make the selector a Subject.
	var subj = createBehaviorSubject({
		onObserversChanged: function(observers) {
			observerCount = observers.length
			if (observerCount === 0) {
				// No subscribers left; remove upstream subscription.
				if(subscription) subscription.unsubscribe()
				subscription = undefined
			} else if (observerCount === 1) {
				// This closure will observe and select from the store.
				// Selectors expect to receive valid states, not undefined, so only call
				// the selector when the state is fully realized.
				var observeState = function() {
					var store = componentInstance.store
					if (!store) return
					var state = store.getState()
					if (state !== undefined) {
						var val = selector(state)
						if (val !== lastSeenValue) { lastSeenValue = val; subj.next(val) }
					}
				}

				subscription = componentInstance.__getSubject().subscribe({ next: observeState })
				observeState()
			}
		}
	})
	Object.assign(selector, subj)

	return selector
}
