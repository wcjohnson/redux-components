# redux-components-list
A List component for redux-components, implementing an array of subcomponents that can be dynamically modified.

## Purpose

redux-components-list provides `ComponentList`, which is a higher-order  [redux-component](https://github.com/wcjohnson/redux-components) that implements an array of state whose nodes can be *dynamically* altered through Redux actions. The sub-array is implemented internally using `ComponentMap`

`ComponentList` is useful when:

- You need to dynamically attach and detach nodes to your Redux state tree at run time. For example, if you are keeping React state in Redux and your React component structure is itself dynamic.
- You need to rehydrate from a state whose shape can only be known at runtime.
- You are developing a component whose subtree's shape depends on component state. The `ComponentList` abstraction contains correct code for this use case, which is not easy to implement while honoring the Redux contract.

`ComponentList` is NOT NEEDED when:

- You are looking for an ordinary array of items inside Redux. Use a plain array for that.

## API

```coffeescript
{ ComponentList } = require 'redux-components-list'
```

### Type Map

`ComponentList` is a higher-order object. Its constructor takes a `typeMap` and returns a `ReduxComponentClass` which can then be mounted to your state tree:
```coffeescript
ComponentList = (typeMap) -> instanceof ReduxComponentClass
```

Fundamentally, the `ComponentList` works by pickling your ReduxComponents into a descriptor that goes into a metadata field in your store. This pickled state should obey the Redux best practice of being a plain, serializable JS object.

To get back and forth between these plain objects and ReduxComponents, the `typeMap` function is provided by the user:
```coffeescript
typeMap = (userTypeDescriptor) -> ComponentDescriptor
```
The `typeMap` must return a [ComponentDescriptor](https://wcjohnson.github.io/redux-components/docs/#createcomponent) which will be passed along to the `createComponent` API in `redux-components`.

This allows you to solve the classical object serialization problem -- how to preserve the type of a serialized object -- in whatever way is appropriate for your problem domain. In most cases, a simple mapping from strings to types will do:
```coffeescript
{ ComponentList } = require 'redux-components-map'
componentTypes = { Component1, Component2, Component3 } = require 'myReduxComponents'
myTypeMap = (descriptor) -> componentTypes[descriptor]
myComponentListClass = ComponentList(myTypeMap)
```

In fact, this use case is so common that an `Object` can be passed directly as the `typeMap` in which case it will be automatically wrapped in a lookup function. The above code is then equivalent to:
```coffeescript
myComponentClass = ComponentMap({ Component1, Component2, Component3 })
```

When using lists, often times all components of the list are the same. An example of this is a React component that embeds a dynamic list of similar subcomponents, with state being kept in Redux. In such cases a `typeMap` might take the form:
```coffeescript
myTypeMap = () -> MyComponent
```
Then use e.g. `componentList.push(true)` to add repeated copies of the generic component.

> **NB:** The typeMap MUST be a pure function of its descriptor. Descriptors MUST be primitives or plain serializable objects.

### Mounting to State Tree

Once you have a component list, you must mount it to a state tree. The following code will mount the compoment list to the root of a fresh Redux store:
```coffeescript
{ createStore } = require 'redux'
{ mountRootComponent } = require 'redux-components'
store = createStore( (x) -> x )
list = new myComponentListClass()
mountRootComponent(store, list)
```
Of course the `ComponentList` is a ReduxComponent, so it can be mounted anywhere you want using the subtree functionality provided by redux-components. You can even put a `ComponentList` in another `ComponentList`!

### Accessing

#### instance.get
```coffeescript
instance.get = (index) -> (instanceof ReduxComponent) | undefined
```
Gets the ReduxComponent instance at the given list position, if it exists, or undefined otherwise.

#### instance.length
```coffeescript
instance.length = integer
```
The number of items in the list.

#### instance.forEach
```coffeescript
instance.forEach = (iterator: (item, index, list) ->, thisArg) -> undefined
```
Calls the iterator function for each item in the list, as in `Array.forEach`

#### instance.map
```coffeescript
instance.map = (iterator: (item, index, list) -> item, thisArg) -> [items...]
```
Calls the iterator function for each item in the list, collecting the return values in an array, as in `Array.foreach`

### Mutating

#### instance.push
```coffeescript
instance.push = (...descriptors) -> undefined
```
Adds elements (obtained by applying `typeMap` to the given descriptors) to the end of the list.

#### instance.unshift
```coffeescript
instance.unshift = (...descriptors) -> undefined
```
Adds elements (obtained by applying `typeMap` to the given descriptors) to the beginning of the list.

#### instance.splice
```coffeescript
instance.splice = (index, howMany, ...descriptors) -> undefined
```
At the given array index, deletes `howMany` elements (can be zero), then adds an element for each provided `descriptor`. Similar to `Array.splice`

> **NB:** Unlike `Array.splice`, negative indices are not accepted and removed data is not returned.

## FAQ

### Why no instance.set?

Think what `instance.set` would mean: you would be changing the descriptor of a component -- the blueprint from which it was constructed -- without unmounting it or changing its internal state.

Attempting to change the descriptor of a component in place is usually indicative of a design problem. ReduxComponents are not state and any state they hold should be in the Redux store. Think carefully about your tree design. Can you accomplish what you want by factoring the mutation down into the subtree as a new action? If so, you should do that! Don't use a fancy dynamic component to skirt around the need for good Redux design.

If after careful thought you find you still need to change the descriptor of a component with the same key, use `splice()` to unmount the existing component, then mount a new one with a new descriptor.

### What do I do with unknown types in my typeMap?

The `ComponentList` will throw an error if at any time the `typeMap` doesn't return a valid ComponentDescriptor when it's called. Thus, if you want to handle unknown data, you must design your `typeMap` so it always returns a ComponentDescriptor even if your app doesn't understand the data type.

Remember, though, that one kind of valid ComponentDescriptor is a plain reducer! So if your `typeMap` wants to handle unknown data, you can just return the identity function as a reducer whenever you see a type you don't know. Then your `ComponentList` will preserve that data unchanged while operating on the types that your `typeMap` understands.
