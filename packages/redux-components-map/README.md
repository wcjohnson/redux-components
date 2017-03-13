# redux-components-map
A Map component for redux-components, implementing a keyed tree of subcomponents that can be dynamically modified.

## Purpose

redux-components-map provides `ComponentMap`, which is a higher-order  [redux-component](https://github.com/wcjohnson/redux-components) that implements a subtree of state whose nodes can be *dynamically* altered through Redux actions. The subtree takes the form of a map data structure with string keys and a redux-component mounted at each key.

`ComponentMap` is useful when:

- You need to dynamically attach and detach nodes to your Redux state tree at run time. For example, if you are keeping React state in Redux and your React component structure is itself dynamic.
- You need to rehydrate from a state whose shape can only be known at runtime.
- You are developing a component whose subtree's shape depends on component state. The `ComponentMap` abstraction contains correct code for this use case, which is not easy to implement while honoring the Redux contract.

`ComponentMap` is NOT NEEDED when:

- You are looking for an ordinary Map data structure inside Redux. Use a plain object for that.
- The shape of your state tree is knowable in advance and does not change at runtime. Use a [pure subtree component](https://wcjohnson.gitbooks.io/redux-components/content/docs/API/createComponent.html) if your tree is not dynamic.

## API

```coffeescript
{ ComponentMap } = require 'redux-components-map'
```

### Type Map

`ComponentMap` is a higher-order object. Its constructor takes a `typeMap` and returns a `ReduxComponentClass` which can then be mounted to your state tree:
```coffeescript
ComponentMap = (typeMap) -> instanceof ReduxComponentClass
```

Fundamentally, the `ComponentMap` works by pickling your ReduxComponents into a descriptor that goes into a metadata field in your store. This pickled state should obey the Redux best practice of being a plain, serializable JS object.

To get back and forth between these plain objects and ReduxComponents, the `typeMap` function is provided by the user:
```coffeescript
typeMap = (userTypeDescriptor) -> ComponentDescriptor
```
The `typeMap` must return a [ComponentDescriptor](https://wcjohnson.gitbooks.io/redux-components/content/docs/API/createComponent.html) which will be passed along to the `createComponent` API in `redux-components`.

This allows you to solve the classical object serialization problem -- how to preserve the type of a serialized object -- in whatever way is appropriate for your problem domain. In most cases, a simple mapping from strings to types will do:
```coffeescript
{ ComponentMap } = require 'redux-components-map'
componentTypes = { Component1, Component2, Component3 } = require 'myReduxComponents'
myTypeMap = (descriptor) -> componentTypes[descriptor]
myComponentMapClass = ComponentMap(myTypeMap)
```

In fact, this use case is so common that an `Object` can be passed directly as the `typeMap` in which case it will be automatically wrapped in a lookup function. The above code is then equivalent to:
```coffeescript
myComponentClass = ComponentMap({ Component1, Component2, Component3 })
```

> **NB:** The typeMap MUST be a pure function of its descriptor. Descriptors MUST be primitives or plain serializable objects.

### API

#### Mounting to State Tree

Once you have a component map, you must mount it to a state tree. The following code will mount the compoment map to the root of a fresh Redux store:
```coffeescript
{ createStore } = require 'redux'
{ mountRootComponent } = require 'redux-components'
store = createStore( (x) -> x )
mapInstance = new myComponentMapClass()
mountRootComponent(store, mapInstance)
```
Of course the `ComponentMap` is a ReduxComponent, so it can be mounted anywhere you want using the subtree functionality provided by redux-components. You can even put a `ComponentMap` in another `ComponentMap`!

#### Accessing

##### mapInstance.get
```coffeescript
mapInstance.get = (key) -> (instanceof ReduxComponent) | undefined
```
Gets the ReduxComponent instance mounted at the given key, if it exists, or undefined otherwise.

##### mapInstance.keys
```coffeescript
mapInstance.keys = -> [ 'key1', 'key2', ... ]
```
Returns a list of the keys of the map, as in `Object.keys()`.

#### Mutating

##### mapInstance.add
```coffeescript
mapInstance.add = (key, userTypeDescriptor) -> undefined
```
Dispatches an action to the store this component is mounted on which will cause `key` to be added to the map, if it is not already there. A new ReduxComponent will be constructed using the `typeMap` by passing the given `userTypeDescriptor`, and mounted at the given key. If the key already exists on the map, an Error will be thrown.

If called on an unmounted ComponentMap, the action will be deferred until after the Map has been mounted. Note that keys added before the map is mounted will not be visible on the Map (i.e. `get()` will return undefined) until after it is mounted.

##### mapInstance.remove
```coffeescript
mapInstance.remove = (key) -> undefined
```
Dispatches an action to the store this component is mounted on which will cause `key` to be removed from the map. The ReduxComponent mounted at the `key` will be unmounted from the store. If no component is mounted at `key`, nothing happens.

If called on an unmounted ComponentMap, the action will be deferred until after the Map has been mounted.

## FAQ

### Why no mapInstance.set?

Think what `mapInstance.set` would mean: you would be changing the descriptor of a component -- the blueprint from which it was constructed -- without unmounting it or changing its internal state.

Attempting to change the descriptor of a component in place is usually indicative of a design problem. ReduxComponents are not state and any state they hold should be in the Redux store. Think carefully about your tree design. Can you accomplish what you want by factoring the mutation down into the subtree as a new action? If so, you should do that! Don't use a fancy map component to skirt around the need for good Redux design.

If after careful thought you find you still need to change the descriptor of a component with the same key, use `remove()` and then `add()` to unmount the existing component, then mount a new one with a new descriptor.

### What do I do with unknown types in my typeMap?

The `ComponentMap` will throw an error if at any time the `typeMap` doesn't return a valid ComponentDescriptor when it's called. Thus, if you want to handle unknown data, you must design your `typeMap` so it always returns a ComponentDescriptor even if your app doesn't understand the data type.

Remember, though, that one kind of valid ComponentDescriptor is a plain reducer! So if your `typeMap` wants to handle unknown data, you can just return the identity function as a reducer whenever you see a type you don't know. Then your `ComponentMap` will preserve that data unchanged while operating on the types that your `typeMap` understands.
