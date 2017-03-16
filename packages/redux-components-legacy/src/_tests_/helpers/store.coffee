{ createStore, applyMiddleware } = require 'redux'
ReduxDebug = require 'redux-debug'
ReduxFreeze = require 'redux-freeze'

makeAStore = (initialState) ->
	createStore( ((x) -> x) , initialState, applyMiddleware(ReduxDebug(console.log), ReduxFreeze) )

module.exports = {
	makeAStore
}
