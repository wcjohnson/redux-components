{ inspect } = require 'util'

{ expect, assert } = require 'chai'
{ createStore, applyMiddleware } = require 'redux'
ReduxDebug = require 'redux-debug'
ReduxFreeze = require 'redux-freeze'
{ createClass, mountComponent, SubtreeMixin, createComponent } = require '..'

describe 'reducer indirection: ', ->
	makeAStore = (initialState) -> createStore( ((x) -> x) , initialState, applyMiddleware(ReduxDebug(console.log), ReduxFreeze) )
	store = makeAStore()

	RootComponent = null
	Subcomponent = null
	rootComponentInstance = null

	describe 'simple: ', ->
		it 'should create subcomponent class', ->
			Subcomponent = createClass {
				displayName: 'Subcomponent'
				verbs: ['SET', 'CHANGE_MAGIC_WORD']
				componentWillMount: ->
					console.log "Subcomponent.willMount: initial state", @state
				componentDidMount: ->
					console.log "Subcomponent.didMount"
				getReducer: (currentState) ->
					(state = {}, action) ->
						switch action.type
							when @SET then Object.assign({}, state, { payload: action.payload or {} })
							when @CHANGE_MAGIC_WORD then Object.assign({}, state, { magicWord: action.payload or 'please'})
							when currentState.magicWord then Object.assign({}, state, {payload: 'got the magic word'})
							else state
				actionDispatchers: {
					setValue: (val) -> { type: @SET, payload: val }
					sayMagicWord: -> { type: @state.magicWord }
					setMagicWord: (val) -> { type: @CHANGE_MAGIC_WORD, payload: val }
				}
				selectors: {
					getValue: (state) -> state
				}
			}

		it 'should create new store', ->
			store = makeAStore({ foo: { magicWord: 'please', payload: 'bar' } })

		it 'should mount subcomponent', ->
			rootComponentInstance = createComponent( { foo: Subcomponent } )
			mountComponent(store, rootComponentInstance)

		it 'should print the whole component tree for your viewing pleasure', ->
			console.log(inspect(rootComponentInstance))

		it 'should respond to stateful action', ->
			rootComponentInstance.foo.sayMagicWord()
			expect(rootComponentInstance.foo.state.payload).to.equal('got the magic word')

		it 'should replace reducer correctly on state change', ->
			rootComponentInstance.foo.setValue('bar')
			expect(rootComponentInstance.foo.state.payload).to.equal('bar')
			rootComponentInstance.foo.setMagicWord('hello')
			expect(rootComponentInstance.foo.state.magicWord).to.equal('hello')
			rootComponentInstance.foo.updateReducer()
			store.dispatch({type: 'hello'})
			expect(rootComponentInstance.foo.state.payload).to.equal('got the magic word')

		it 'should print the whole component tree for your viewing pleasure', ->
			console.log(inspect(rootComponentInstance))
