{ expect } = require 'chai'
{ createStore } = require 'redux'

createClass = require '../createClass'
mountComponent = require '../mountComponent'

describe 'basic functions: ', ->
	makeAStore = -> createStore( (x) -> x )
	store = makeAStore()

	RootComponent = null
	Subcomponent = null
	rootComponentInstance = null

	describe 'trivial component: ', ->
		it 'should create fresh store', ->
			store = makeAStore()

		it 'should create class', ->
			Subcomponent = createClass {
				displayName: 'Subcomponent'
				getReducer: -> (state = {}, action) ->
					switch action.type
						when 'SET' then action.payload or {}
						else state
			}

		it 'should mount instance of class on store', ->
			rootComponentInstance = new Subcomponent()
			mountComponent(store, rootComponentInstance)

		it 'should know about the store', ->
			expect(rootComponentInstance.store).to.equal(store)

		it 'should set the default state', ->
			expect(store.getState()).to.deep.equal({})

		it 'should respond correctly to an action', ->
			store.dispatch({type: 'SET', payload: { hello: 'world'} })
			expect(store.getState()).to.deep.equal({hello: 'world'})

	describe 'component with scoped data: ', ->
		it 'should create fresh store', ->
			store = makeAStore()

		it 'should create class', ->
			Subcomponent = createClass {
				displayName: 'Subcomponent'
				verbs: ['SET']
				getReducer: -> (state = {}, action) ->
					switch action.type
						when @SET then action.payload or {}
						else state
				actionCreators: {
					setValue: (val) -> { type: @SET, payload: val }
				}
				selectors: {
					getValue: (state) -> state
					amIBound: (state) -> @SET
				}
			}

		it 'should mount instance of class on store', ->
			rootComponentInstance = new Subcomponent()
			mountComponent(store, rootComponentInstance)

		it 'should set the default state', ->
			expect(store.getState()).to.deep.equal({})

		it 'should scope verbs', ->
			expect(rootComponentInstance.SET).to.equal(':SET')

		it 'should bind selectors to this', ->
			expect(rootComponentInstance.amIBound()).to.equal(':SET')

		it 'should respond correctly to an action from a scoped creator', ->
			store.dispatch(rootComponentInstance.setValue( { hello: 'world'} ))
			expect(store.getState()).to.deep.equal( { hello: 'world'} )

		it 'should return scoped data from selector', ->
			expect(rootComponentInstance.getValue()).to.deep.equal( { hello: 'world'} )
