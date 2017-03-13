# 0.1

### Preloading

It is now possible to call `ComponentMap.add` and `ComponentMap.remove` on an unmounted ComponentMap. This will preload the ComponentMap, and when it is mounted, the preloaded components will be attached to the Map.

### Object as typeMap

You can now pass an `Object` as the `typeMap` in the higher-order `ComponentMap(typeMap)` constructor. Passing an object `obj` is equivalent to passing a simple lookup function of the form `(key) -> obj[key]`.

This simplifies the most common use case.

### Miscellaneous fixes

- Redux is listed as a dependency rather than a peerDependency.
- `redux-components^0.3.1` is now required.
- APIs updated for redux-components 0.3
- Switched to an internal implementation of combineReducers that doesn't throw unexpected shape warnings when rehydrating a ComponentMap.
