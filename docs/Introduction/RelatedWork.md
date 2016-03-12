# Those Who Have Gone Before

react-components takes cues from the fine work of many peer projects and parallel lines of work. Here are the ones we know of:

### Ducks

The notion of bundling a reducer with its related action creators and selectors in one's component model comes from [Ducks](https://github.com/erikras/ducks-modular-redux) by @erikras. redux-components builds on the "duck" design pattern by promoting it to a first-class logical model in the code, rather than a mental model or physical bundle of files.

### redux-orm

Many use cases for redux-components were "mini-ORM" tools. [redux-orm](https://github.com/tommikaikkonen/redux-orm), which wasn't a thing when we started making redux-components, does a good job of implementing basic ORM patterns in Redux. redux-components are more general tools than redux-orm is, but if you need quick drop-in ORM like behavior, redux-orm will get you there faster.
