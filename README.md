# redux-components

[![npm](https://badge.fury.io/js/redux-components.svg)](https://www.npmjs.com/package/redux-components)
[![Join the chat at https://gitter.im/redux-components/Lobby](https://badges.gitter.im/redux-components/Lobby.svg)](https://gitter.im/redux-components/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

> Are you looking for the redux-components website? It's here: [https://wcjohnson.github.io/redux-components](https://wcjohnson.github.io/redux-components)

A component model for Redux state trees based on the React.js component model and other familiar design patterns from the React ecosystem.

> **NB:** redux-components 0.4 is built on ES2017+ JavaScript and is a major breaking change from 0.3. If you've written code against the 0.3 or earlier branches, you can stay on the 0.3 branch. If you want to migrate, you should check out [redux-components-legacy](https://github.com/wcjohnson/redux-components/tree/master/packages/redux-components-legacy) for the recommended migration path.

## Install

```
$ npm install --save redux-components
```

## Learn

Documentation: [https://wcjohnson.github.io/redux-components/docs/](https://wcjohnson.github.io/redux-components/docs/)

Feel free to ask any questions on Gitter: [https://gitter.im/redux-components/Lobby](https://gitter.im/redux-components/Lobby)

## Develop

This is a mono-repo for `redux-components` and related packages. Please see [the packages folder](/packages) for details on individual components.

The build chain is based on [Lerna](https://lernajs.io/). `npm install`, `lerna bootstrap`, `lerna run build` should build all the packages.
