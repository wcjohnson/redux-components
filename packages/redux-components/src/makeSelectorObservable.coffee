import { removeFromList } from './util'
import $$observable from 'symbol-observable'
import ReduxComponent from './ReduxComponent'

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

# Property definition for Symbol.observable
observablePropertyDefinition = { writable: true, configurable: true, value: (-> @) }

selectorIsBeingObserved = (isBeingObserved) ->
	selector = @; componentInstance = @__componentInstance
	if isBeingObserved
		lastSeenValue = undefined

		# If component isn't mounted, defer.
		if not componentInstance.isMounted()
			componentInstance.__deferObservedSelectors = (componentInstance.__deferObservedSelectors or []).concat([selector])
			return

		# Closure to detect changes in the selector.
		observeState = ->
			val = selector(componentInstance.store.getState())
			if val isnt lastSeenValue
				lastSeenValue = val; selector.next(val)

		# Connect to the store; observe the initial state.
		@__unsubscriber = componentInstance.store.subscribe(observeState)
		observeState()
	else
		# If component isn't mounted, clear deferral.
		if not componentInstance.isMounted()
			removeFromList(componentInstance.__deferObservedSelectors, selector)
			return

		# Unsubscribe from the store if previously subscribed.
		@__unsubscriber?(); delete @__unsubscriber
	undefined

# Make a selector on a ReduxComponentInstance into an ES7 Observable.
export default makeSelectorObservable = (componentInstance, selector) ->
	# Make the selector a Subject.
	Object.assign(selector, subjectMixin)
	# Make the selector an ES7 Observable
	Object.defineProperty(selector, $$observable, observablePropertyDefinition)
	# Store the componentInstance on the selector.
	selector.__componentInstance = componentInstance
	# Attach the observation function
	selector.__isBeingObserved = selectorIsBeingObserved
	# Return the selector
	selector

# Make all selectors on the given component instance observable.
export makeSelectorsObservable = (componentInstance) ->
	if not (componentInstance instanceof ReduxComponent)
		throw new Error("makeSelectorsObservable: argument must be instanceof ReduxComponent")

	if componentInstance.selectors
		makeSelectorObservable(componentInstance, componentInstance[selKey]) for selKey of componentInstance.selectors
	componentInstance
