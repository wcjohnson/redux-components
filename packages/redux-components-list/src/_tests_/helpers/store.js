import { createStore, applyMiddleware } from 'redux'
import ReduxDebug from 'redux-debug'
import ReduxFreeze from 'redux-freeze'

export function makeAStore(initialState) {
  return createStore((function(x) {
    return x;
  }), initialState, applyMiddleware(ReduxDebug(console.log), ReduxFreeze));
}
