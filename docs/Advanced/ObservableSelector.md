# Observable Selectors

Redux 3.6.x adds the ability for Stores to function as [ES7 Observables](https://github.com/tc39/proposal-observable). Building on this capability, Redux Components 0.2.x now allows `selectors` that are specified on your components to be used as [Observables](https://github.com/tc39/proposal-observable) as well.

## Functionality

Observable selectors are provided by adding the `ObservableSelectorMixin` to your component class:
```coffeescript
{ ObservableSelectorMixin, createClass } = require 'redux-components'

MyClass = createClass {
	mixins: [ ObservableSelectorMixin ]
	...
	selectors: {
		mySelector: (state) -> state.myValue
	}
	...
}
```

Behind the scenes, this mixin ensures that when an instance of your component is mounted, all of the `selectors` on the instance will be augmented to conform to the [ES7 Observable](https://github.com/tc39/proposal-observable) pattern.

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

- Your component must be mounted to a store before you may subscribe to observable selectors. (This means, inter alia, that while inside a component's `componentWillMount` method, you cannot observe the selectors of that component. You must wait until `componentDidMount`.)
