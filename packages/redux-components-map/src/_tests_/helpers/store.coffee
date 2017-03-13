{ createStore, applyMiddleware, compose } = require 'redux'
ReduxDebug = require 'redux-debug'
ReduxFreeze = require 'redux-freeze'
instrument = (require 'redux-devtools-instrument').default
cuid = require 'cuid'

makeAStore = (initialState) ->
	store = createStore( ((x) -> x) , initialState, applyMiddleware(ReduxDebug(console.log), ReduxFreeze) )

makeDevToolsStore = (initialState, monitorReducer) ->
	enhancer = compose(
		applyMiddleware(ReduxDebug(console.log), ReduxFreeze)
		instrument(monitorReducer)
	)
	store = createStore( ((x) -> x) , initialState, enhancer )

testComponentMixin = {
	verbs: ['SET']
	componentWillMount: ->
		@iid = cuid()
		console.log "#{@displayName} #{@iid} willMount with initial state:", @state
	componentDidMount: ->
		console.log "#{@displayName} #{@iid} didMount"
		@set('mounted')
	componentWillUnmount: ->
		console.log "#{@displayName} #{@iid} willUnmount"
	getReducer: ->
		(state = null, action) ->
			# console.log "#{@displayName} #{@iid} reducer action,state", action, state
			value = switch action.type
				when @SET then action.payload or {}
				else state
			# console.log "#{@displayName} #{@iid} reducer nextState", value
			value
	actionDispatchers: {
		set: (x) -> { type: @SET, payload: x }
	}
	get: -> @state
}

module.exports = {
	makeAStore, testComponentMixin, makeDevToolsStore
}
