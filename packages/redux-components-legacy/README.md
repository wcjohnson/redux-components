# redux-components-legacy
Implementation of the `redux-components` 0.3.x API on top of the new 0.4.x infrastructure. Designed as an aid in porting old code that uses the 0.3.x API.

## Usage

- Install: `$ npm install --save redux-components-legacy`

- Replace `require('redux-components')` with `require('redux-components-legacy')`. The exports and API are the same as 0.3.x.

- `redux-components-legacy` passes all of the `redux-components` 0.3.x unit tests and should work as a drop in replacement. Please file an issue if this is not the case.

## Legacy Documentation

The `redux-components` 0.3.x API documentation [is available here](docs). This is for reference only; new code should be written to the 0.4 API and this documentation will not be updated in the future.
