# Observable Selectors

Redux 3.6.x adds the ability for Stores to function as [ES7 Observables](https://github.com/tc39/proposal-observable). Building on this capability, Redux Components 0.2.x now allows `selectors` that are specified on your components to be used as [Observables](https://github.com/tc39/proposal-observable) as well.

## Functionality

When declaring a class, any functions specified under the `selectors` key will automatically be converted into ES7 Observables:

```coffeescript
{ createClass } = require 'redux-components'

MyClass = createClass {
	...
	selectors: {
		mySelector: (state) -> state.myValue
	}
	...
}
```

Here are the details:

- To watch an observable selector for changes, you call the `subscribe(Observer)` method on the selector, passing an object that conforms to the ES7 `Observer` interface. The `subscribe` method returns an ES7 `Subscription` object that can be used to unsubscribe later.
```coffeescript
subscription = myClassInstance.mySelector.subscribe({
	next: (value) -> console.log "mySelector just changed value:", value
})
...
subscription.unsubscribe()
```

- An observable selector will call `observer.next(value)` on each observer immediately with the value of the selector at initialization time, and then subsequently whenever the value returned by the selector would change. It always passes the current value of the selector.

- An observable selector is what is sometimes called a "hot observable" -- it never calls `observer.complete()`. It also never calls `observer.error()`, even if your selector throws an error.

- Observable selectors assume conformance with the Redux contract, and therefore use identity (`===`) comparison to detect changes. Your Redux stores are expected to return unequal objects when changes are made.

- Selectors are only active when a component is mounted. You may still attach an `Observer` to a selector even when a component is not mounted, but the `Observer` will not be attached until it is.
