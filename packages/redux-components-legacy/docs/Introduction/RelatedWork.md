# Those Who Have Gone Before

redux-components takes cues from the fine work of many peer projects and parallel lines of work. There are also projects out there that cover similar use cases. Here are the ones we know of:

### Ducks

The notion of bundling a reducer with its related action creators and selectors in one's component model comes from [Ducks](https://github.com/erikras/ducks-modular-redux) by @erikras. redux-components builds on the "duck" design pattern by promoting it to a first-class logical model in the code, rather than only a mental model or physical bundle of files.

### React + react-router

Some time ago, our team dropped Angular for a frontend platform based on [React](https://facebook.github.io/react/) and [react-router](https://github.com/reactjs/react-router). The reusability of React components and the refactorability of react-router's declarative route tree were both inspirations for the design of redux-components.

### redux-orm

Many use cases for redux-components were "mini-ORM" tools. [redux-orm](https://github.com/tommikaikkonen/redux-orm), which wasn't a thing when we started making redux-components, does a good job of implementing basic ORM patterns in Redux. redux-components are more general tools than redux-orm is, but if you need quick drop-in ORM like behavior, you may want to look at redux-orm.
