## TOC

## Before We Begin

> Example code in this document is written in ES2015+ syntax. In particular, you will need
> `babel-plugin-transform-class-properties` and `babel-plugin-transform-decorators-legacy`
> to compile the examples as written.

## Components

The fundamental building block of `redux-components` is the Redux component, which is an instance of any class that derives from the base class `ReduxComponent` -- analogous to the React class `React.Component`.

### What's in a Component?

Let's break down a Redux component and see what it's made of. Our case study is the `SimpleComponent`: a piece of state that stores and retrieves an opaque, raw value. `SimpleComponent`'s class looks like this:

```javascript
import { ReduxComponent, action, selector } from 'redux-components'

export class SimpleComponent extends ReduxComponent {
  static verbs = ['SET']

  reducer(state = null, action) {
    switch(action.type) {
      case this.SET:
        return (action.payload === undefined) ? null : action.payload

      default:
        return state
    }
  }

  @action({isDispatcher: true})
  set(value) {
    return { type: this.SET, payload: value }
  }

  @selector()
  get(state) {
    return state
  }
}
```

As you can see, our `SimpleComponent` consists of four fundamental parts: **verbs**, a **reducer**, an **action**, and a **selector**. Let's go over each of these in turn.

#### Verbs

You'll know from the Redux documentation that your application state is manipulated only by actions, and that every action has a `type`.

Well, verbs are strings that serve as the `type`s of actions. Think of them as what the reducer looks at when it decides what to do. In baseline Redux, verbs are just plain strings -- but in redux-components they have some additional "magic" behavior designed to help you reuse components more easily, which we will explain later. For now, just think of them as names for the things you want your reducer to do.

As you can see, our `SimpleComponent` does only one thing: `SET`.

#### Reducer

Reducers are a fundamental part of Redux covered very well in the Redux docs, so I won't belabor matters by repeating the basics. However, there are a few important things about reducers that are specific to redux-components:

  - Reducers are automatically bound to their component instance by the redux-components framework. This means you don't have to worry about binding them when you hand them off to Redux or other code. They will always be called in the context of their owning instance.

  - Because they are bound, they have access to the verbs of their component instance. So instead of writing a plain string for a verb, you should write `this.VERB`. This will ensure your reducer responds to scoped actions, which have to do with the "magic" verb behavior I referred to earlier. (Don't worry, we'll get to that shortly.)

  - Again because they are bound, it can be tempting to introduce impure behavior in your reducer, say by calling a method on `this`, or storing some data on `this.someKey`. *Do not be tempted to do this!* If you do, you will break the Redux contract and lose a lot of the advantages that Redux gives you. The basic rule of reducers in redux-components is the same as in Redux: **reducers should be pure functions of state and action!**

  > Verbs are a special exception; they are constant throughout the life of a component and therefore safe to access from the reducer.

  - redux-components expects reducers to obey the Redux contract in all respects. In particular, you should make sure your reducer only returns an identical (`===`) state when nothing in the state has changed.

Our `SimpleComponent` has an appropriately simple reducer: when it hears the action named `this.SET`, it changes the state to the attached `payload`. It ignores all other actions.

#### Actions

Redux actions are plain objects with a string `type` key, used by reducers to transform state. They are created by "action creators" and then dispatched to the Redux store using `store.dispatch()`. redux-components adds some magic around the Redux action model to make them easier to use.

An action is a method on your component class with the **`@action` decorator** applied to it. This decorator tells redux-components that you want your method to be an action, and applies the appropriate properties to it. All actions are bound to the component instance, just like reducers.

By default, adding `@action()` to a method makes a plain Redux action creator. However, in this particular case, by passing `{isDispatcher: true}` to the `@action` decorator we are making our action a **dispatcher**. Dispatchers are automatically wrapped in a `store.dispatch()` call, so that there is no need for you to call dispatch yourself.

So in the case of our `SimpleComponent`, whenever we call `component.set(value)`, an action will automatically be dispatched to the containing store of the type `component:SET` and the given value. This will have the semantic effect of setting our component's value, so the code reads as what it does.

#### Selectors

A **selector**, described in the Redux docs under [Computing Derived Data](http://redux.js.org/docs/recipes/ComputingDerivedData.html), is a pure function that takes the state of the Redux store and returns some portion of interest, possibly transforming it somehow along the way. Think of selectors as the vehicles that let you get exactly what you want out of your Redux store.

Selectors in redux-components are methods on component classes with the **`@selector` decorator** applied to them. Redux-components adds some magic to selectors to make them better. In particular, selectors in redux-components are **scoped** by default -- instead of receiving the state of the whole Redux store, they receive the state of the component instance they are attached to. This makes it easy to write components that don't depend on the state shape of the application they are used in. Selectors are also bound to the instance and so have access to all the instance's properties.

Our `SimpleComponent` has a selector `component.get()`, which will simply return the state of the component, which is the last value set with `component.set(value)` or null.

### Connecting to a Store

Okay, we've made a Redux component. How do we use it?

First we should note that what we made was a *class* of Redux components. Only *instances* can actually be used. We get an instance in the usual way: by calling `new SimpleComponent()`. First we create an instance, then we use that instance by **mounting** it to a store:

```javascript
import { createStore } from 'redux'
import { mountRootComponent } from 'redux-components'
import { SimpleComponent } from 'SimpleComponent'

// Create an instance of our SimpleComponent
var simpleComponentInstance = new SimpleComponent()
// Create a store with the identity function for a reducer
var store = createStore( x => x )
// Mount our component on the store. This automatically replaces the store's
// reducer using .replaceReducer
mountRootComponent(store, simpleComponentInstance)

// Now we can use our component!
simpleComponentInstance.set('hello world')
assert(simpleComponentInstance.get() === 'hello world')
```

### Component Lifecycle

By analogy with React, Redux component instances have a **lifecycle**. The lifecycle has four phases, corresponding to four **lifecycle methods** that will be called on the component during that phase of the lifecycle. All of these methods are optional.

#### constructor

As a regular JS object, your component's `constructor` will be called when an instance is created.

> Note that redux-components that define a constructor must **always** call the `super()` constructor. If you don't, your component will not function properly!

#### componentWillMount

`component.componentWillMount()` is called when your component is about to be mounted to a store. At this time, the `this.store` object is available and the `this.state` field will contain your component's initial state, if any.

At this time, your component's reducer *has not* been attached to the store, so any actions you dispatch from here *will not* be seen by your reducer.

#### componentDidMount

`component.componentDidMount()` is called *after* your component's reducer has been attached to a store. At this time, your reducer will see any action that you dispatch and your state will change accordingly.

> If you're wondering where to put your state initialization code, `componentDidMount` is usually the right place. You will probably want to dispatch actions that change your state's value, which won't work in `componentWillMount`.

#### componentWillUnmount

`component.componentWillUnmount()` is called when your component is about to be unmounted from the store. At this time, your component is still mounted, so any *synchronous* actions will be seen by your reducer.

## Trees

Sooner or later, you will want to put multiple components together to form a composite application. In Redux, the primary manifestation of this pattern is the **state tree**, which is put together using Redux's `combineReducers()` function.

In redux-components, we provide similar methods to build composite components out of smaller ones.

### createComponent

The easiest way to create a tree in redux-components is via the `createComponent` API, which allows you to quickly and legibly compose many components into any shape:

```javascript
import { createComponent } from 'redux-components'
import { SimpleComponent } from 'SimpleComponent'

var tree = createComponent({
  a: new SimpleComponent(),
  b: SimpleComponent,
  deep: {
    deeper: {
      c: (state = null, action) => action.payload || state,
      d: SimpleComponent
    }
  }
})
```

`createComponent`, when given an object literal, creates an instance of a component tree with the components you specify attached at each corresponding node. In fact, this bears a little further explanation, so let's go into detail. `createComponent(descriptor)` takes a **component descriptor** as an argument, which can be one of four types:

- **Component instance:** In this case, since `instance` is already a component, `createComponent(instance)` is just `instance`. In the above example, `tree.a` is a component instance descriptor.

- **Component class:** In this case, `new Class()` is immediately called to create an instance. In the above example, `tree.b` is a component class descriptor.

- **Plain reducer:** You may provide a reducer function as a component descriptor, in which case the reducer is automatically lifted to a full-fledged component instance. Using plain reducers, you can attach other code from the Redux ecosystem, or code you have not yet ported to redux-components. In the above example, `tree.deep.deeper.c` uses a plain reducer descriptor.

- **Object literal:** You may pass an object as a component descriptor, in which case the object will be swept up into a tree, with `createComponent()` being called recursively on each node. Provide a component descriptor at each node (including deeper levels of nesting) and `createComponent` will automatically create the corresponding component tree.

When you create a tree with `createComponent`, the components are accessible via object properties at their corresponding position in the tree. For instance, `tree.deep.deeper.d` is an instance of `SimpleComponent`

### Scoping

Remember the discussion about verbs and the "magic" behavior that I said I'd explain later? Well, now that you know about trees, it's time to clear all that up. Redux components are designed around the idea of **scoping**, which means following these rules to the greatest extent possible:

1. **Components should be isolable:** A component should care about its own state and the state of its children, not about the state at other nodes of the tree, nor about its specific position.

1. **Components should be reusable:** A component should be able to attach at multiple nodes in a tree, or move across different applications when appropriate.

1. **Components should be refactorable:** You should be able to split a component into child components, meld separate components, and move components around your state tree without breakage, so long as you expose a consistent API.

#### Path-Awareness

In Redux, if you generate a reducer that mutates state when hearing the verb `SET`, and then use `combineReducers()` to connect multiple copies of this reducer into a state tree, what happens when you dispatch an action of type `SET`?

Right, *all* of the nodes where you attached that reducer will change their state! This is usually not what you want, and it exposes a fundamental problem with basic Redux composition: *plain reducers are neither isolated nor reusable!*

In redux-components, we address this issue by making components **path-aware**. Every component instance, after it is mounted, has a `this.path` property containing an array path from the root of the store to the state of this mounted component. Using this information, we can scope component instances to their position in the tree, as follows:

#### Scoped Verbs

When you declare a static `verbs` field on your component class (which must be an array of plain strings) you are telling redux-components to generate a list of **scoped verbs** on each instance of your component when it mounts. The scoped verbs are transformed at mount time into plain strings on the instance. (of the form ```this[verb] = `${this.path}:${verb}` ```)

The payoff is that by using *scoped* verbs, when you have a bunch of instances of the same component with the same reducer all attached to the same state tree, you can target any *single* instance with an action *by using a scoped verb as the action type!* Only the reducer of the specific component that recognizes the scoped verb will respond.

This requires some changes at the point where verbs are created (actions) and the point where verbs are received (reducers): instead of specifying a plain string as you would in Redux, instead you specify `this.[verb]`, e.g. `this.SET` for the scoped verb `SET`. Then your action dispatchers will dispatch, and your reducers will reduce over, scoped verbs rather than fixed strings.

And now you should understand why, in our `SimpleComponent`, our reducer and action dispatcher used `this.SET` as the action type, instead of just `"SET"`.

> Most of the time you will want the behavior of scoped verbs, but sometimes you will want the default behavior where multiple components respond identically to the same verb. No problem! Just omit declaring a verb altogether and use plain strings in your reducer and actions. This falls back cleanly onto default Redux behavior.

#### Scoped Selectors

In addition to scoping the way we update our store, we'll also need to scope the way we retrieve from the store. That's where **scoped selectors** come in. Rather than operating on the state of the store as a whole, a scoped selector operates only on the state of the node where it is mounted.

This means that each instance of `SimpleComponent` mounted on our example state tree will see only its local state: `tree.deep.deeper.d.get()` will return the value at `store.getState().deep.deeper.d`.

## Higher-Order Components

Trees are one way to compose pieces of functionality into larger wholes. Another technique is by way of **higher-order components**. A higher-order component is a function that takes a Redux component class, transforms it by adding some functionality, and returns a new Redux component class.

redux-components ships with just one higher-order component, `withSubtree()`. (In fact, all the tree patterns in redux-components are implemented using this HOC!)

### withSubtree

Suppose you want to write a type of component that has some functionality of its own, but also has child components. That's where the **withSubtree** HOC comes in:

```javascript
import { ReduxComponent, withSubtree, mountRootComponent } from 'redux-components'
import { SimpleComponent } from SimpleComponent
import { createStore } from 'redux'

// Create a parent SimpleComponent class that embeds a child SimpleComponent at
// `this.child`.
const ParentComponent = withSubtree( () => {
  child: SimpleComponent
})(SimpleComponent)

var parent = new ParentComponent()
var store = createStore( x => x )
mountRootComponent(store, parent)

// These will all dispatch the appropriate actions, scope properly, etc.
parent.set('hello world')
parent.child.set('goodbye world')
assert(parent.get() === 'hello world')
assert(parent.child.get() === 'goodbye world')
```

This will create a new class, related to `SimpleComponent`, but with an instance of `ChildComponent` automatically mounted at `this.child` when the `ParentComponent` mounts.

Specifically, here's how `withSubtree` works:

- `withSubtree(getSubtree)` takes a function called `getSubtree`. The `getSubtree()` function takes no arguments and must return an object-type component descriptor (see `createComponent`). `withSubtree` then returns a higher-order component, which takes a base class and creates a new class.

- During `componentWillMount`, the new class will call the `getSubtree()` function. It will create the subtree using the descriptor just as `createComponent()` does.

- The reducer for the new class will first call the reducers for the subtree and combine them. It will then call the reducer method of the base class with the combined and merged state. Your reducer will therefore see the result of all the child reducers in the incoming state.

>Before, I mentioned that all the subtree functionality of `createComponent` is in fact implemented using `withSubtree`. Here's how it works:
>```javascript
function createTreeComponent(shape) {
  var clazz = withSubtree(() => shape)(ReduxComponent)
  return new clazz()
}
```

## State Changes

We've talked about how to design components, access their state, mutate them by sending actions, and compose them into larger wholes. But what about interaction? How do you look for and respond to state changes?

In redux-components, this is achieved using [TC39 Observables](https://github.com/tc39/proposal-observable) in combination with the selector pattern we've already described.

### Observable Selectors

Any selector on any Redux component can be turned into an `Observable` by adding `{isObservable: true}` to the decorator options in the class. In the `SimpleComponent` example:

```javascript
@selector({isObservable: true})
get(state) { return state }
```

This causes every instance of `SimpleComponent` to attach `Observable` interop points to the `get()` selector. You can use it like so:
```javascript
import { createStore } from 'redux'
import { mountRootComponent } from 'redux-components'
import { SimpleComponent } from 'SimpleComponent'
// You can use any TC39-compatible Observable library... zen, rx5, etc.
import Observable from 'zen-observable'

var simpleComponentInstance = new SimpleComponent()
var store = createStore( x => x )
mountRootComponent(store, simpleComponentInstance)

simpleComponentInstance.set('hello world')

// A selector with `isObservable: true` exports an Observable symbol, so it
// can be used with the `Observable.from` method of your preferred
// TC39-compliant implementation.
var currentState = Observable.from(simpleComponentInstance.get)

// The Observable produced by redux-components emits a value every time its
// associated selector changes value. It caches the current value of the
// selector and feeds it to each new subscriber. It never stops emitting.
// It will emit an error only when the associated selector throws.

// This will immediately print 'hello world', because new subscribers always
// get called with the current value. (BehaviorSubject in rxjs terminology)
var subscription = currentState.subscribe({
  next: (nextState) -> console.log("I just saw a state change:", nextState)
})

// This will cause a state change, and your observer will then print
// 'goodbye world'
simpleComponentInstance.set('goodbye world')
```

- The `Observable` produced by an observable selector is a so-called "hot observable" -- it continuously emits values throughout the life of your component. It will never emit `complete` and it will only emit `error` if the selector throws an error.

- The `Observable`s are also `BehaviorSubject`s (in RxJS terminology) in that they store their current value and will always emit their current value to a new subscriber, even if the component doesn't change state.

- redux-components doesn't depend on or import any particular observable library; we write to the TC39 API and you can choose your preferred implementation thereof. redux-components is *not compatible* with pre-TC39 legacy observable libraries. You will have to shim them to TC39 if you want compatibility.

## Patterns

### Singleton Components

Create component instances as singletons. Mount all your singletons with createComponent. Reference the singletons in your state code and then you can refactor your tree at will without breakage.

## Antipatterns

## FAQ

> **Q:** I can't (or don't want to) use future JavaScript syntax like decorators and member variables. Can I still use redux-components?

**A:** Yes! We provide shims to apply decorators using normal syntax. It's less pretty, but it works just the same. Here's the `SimpleComponent` example, rewritten using only ES2015 standard syntax:

```javascript
// Import the `decorate` shim...
import { ReduxComponent, action, selector, decorate } from 'redux-components'

// Write an ES2015 class without decorators or member variable syntax...
export class SimpleComponent extends ReduxComponent {
  reducer(state = null, action) {
    switch(action.type) {
      case this.SET:
        return (action.payload === undefined) ? null : action.payload

      default:
        return state
    }
  }

  set(value) {
    return { type: this.SET, payload: value }
  }

  get(state) {
    return state
  }
}

// Instead of static verbs = ['SET'] in the class body (ES2017 member syntax)
// you can attach static values outside the class body, like so:
SimpleComponent.verbs = ['SET']

// By importing the `decorate` shim from redux-components, you can avoid
// decorator syntax and apply the decorators imperatively:
decorate(SimpleComponent, {
  set: action({isDispatcher: true})
  get: selector()
})
```
