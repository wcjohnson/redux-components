import { removeFromList, assign } from './util'
import $$observable from 'symbol-observable'

# A quick and dirty "Subject" mixin.
# XXX: Would like to depend on a trusted library here, but the only one I know of is rxJS which is simply too bloated.
# zen-observable does not provide a Subject implementation.
reentrantMutation = (self) ->
	# Reentrant mutation safety: make a copy of the observer list in case it is currently being
	# iterated.
	if not self.__nextObservers then self.__nextObservers = []
	if self.__nextObservers is self.__currentObservers
		self.__nextObservers = self.__currentObservers.slice()
	undefined

subjectMixin = {
	next: (x) ->
		observers = @__currentObservers = @__nextObservers
		if observers
			observer.next?(x) for observer in observers
		undefined

	subscribe: (observer) ->
		reentrantMutation(@)
		@__nextObservers.push(observer)
		if @__nextObservers.length is 1 then @__isBeingObserved?(true)
		# Subscription object
		{
			unsubscribe: =>
				reentrantMutation(@)
				removeFromList(@__nextObservers, observer)
				if @__nextObservers.length is 0 then @__isBeingObserved?(false)
				undefined
		}
}

# Make a selector on a ReduxComponentInstance into an ES7 Observable.
export default makeSelectorObservable = (componentInstance, selector) ->
	# Make the selector a Subject.
	assign(selector, subjectMixin)

	# Make the selector an ES7 Observable
	Object.defineProperty(selector, $$observable, { writable: true, configurable: true, value: (-> @) })

	# Attach the selector to the Redux store when it is being observed.
	selector.__isBeingObserved = (isBeingObserved) ->
		if isBeingObserved
			lastSeenValue = undefined
			observeState = ->
				val = selector(componentInstance.store.getState())
				if val isnt lastSeenValue then lastSeenValue = val; selector.next(val)

			observeState()
			@__unsubscriber = componentInstance.store.subscribe(observeState)
		else
			@__unsubscriber?(); delete @__unsubscriber
		undefined