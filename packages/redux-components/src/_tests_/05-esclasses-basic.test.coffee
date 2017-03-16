{ expect } = require 'chai'
{ inspect } = require 'util'

{ mountRootComponent, createComponent, ReduxComponent, decorate, action, selector } = require '..'
{ makeAStore } = require './helpers/store'

describe 'ES classes: ', ->
	store = makeAStore()

	RootComponent = null
	Subcomponent = null
	rootComponentInstance = null

	describe 'trivial component: ', ->
		it 'should create class', ->
			class Subcomponent extends ReduxComponent
				reducer: (state = {}, action) ->
					switch action.type
						when 'SET' then action.payload or {}
						else state

		it 'should mount instance of class on store', ->
			store = makeAStore()
			rootComponentInstance = new Subcomponent()
			expect(rootComponentInstance.isMounted()).to.not.be.ok
			mountRootComponent(store, rootComponentInstance)
			expect(rootComponentInstance.isMounted()).to.be.ok

		it 'should know about the store', ->
			expect(rootComponentInstance.store).to.equal(store)

		it 'should set the default state', ->
			expect(store.getState()).to.deep.equal({})
			expect(rootComponentInstance.state).to.deep.equal({})

		it 'should respond correctly to an action', ->
			store.dispatch({type: 'SET', payload: { hello: 'world'} })
			expect(store.getState()).to.deep.equal({hello: 'world'})
			expect(rootComponentInstance.state).to.deep.equal({hello: 'world'})

	describe 'component with magic binding: ', ->
		it 'should create class', ->
			class Subcomponent extends ReduxComponent
				reducer: (state = {}, action) ->
					switch action.type
						when @SET then action.payload or {}
						else state

				setValue: (val) -> { type: @SET, payload: val }

				getValue: (state) -> state
				amIBound: (state) -> @SET

				@verbs = ['SET']

			decorate(Subcomponent, {
				setValue: action()
				getValue: selector()
				amIBound: selector()
			})

		it 'should mount instance of class on store', ->
			store = makeAStore()
			rootComponentInstance = new Subcomponent()
			expect(rootComponentInstance.isMounted()).to.not.be.ok
			mountRootComponent(store, rootComponentInstance)
			expect(rootComponentInstance.isMounted()).to.be.ok

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

	describe 'subclassing with magic binding: ', ->
		it 'should create classes', ->
			class RootComponent extends ReduxComponent
				setValue: (val) -> { type: @SET, payload: val }
				getValue: (state) -> state
				amIBound: (state) -> @SET

				@verbs = ['SET']

			decorate(RootComponent, {
				setValue: action()
				getValue: selector()
				amIBound: selector()
			})

			class Subcomponent extends RootComponent
				reducer: (state = {}, action) ->
					switch action.type
						when @SET then action.payload or {}
						when @MYSET then 42
						else state

				mySet: -> { type: @MYSET }
				myGet: (state) -> @MYSET

				@verbs = ['MYSET']

			decorate(Subcomponent, {
				mySet: action()
				myGet: selector()
			})

		it 'should mount instance of class on store', ->
			store = makeAStore()
			rootComponentInstance = new Subcomponent()
			expect(rootComponentInstance.isMounted()).to.not.be.ok
			mountRootComponent(store, rootComponentInstance)
			expect(rootComponentInstance.isMounted()).to.be.ok

		it 'should dump instance', ->
			console.log(inspect(rootComponentInstance))

		it 'should scope verbs', ->
			expect(rootComponentInstance.SET).to.equal(':SET')
			expect(rootComponentInstance.MYSET).to.equal(':MYSET')

		it 'should bind selectors to this', ->
			expect(rootComponentInstance.amIBound()).to.equal(':SET')
			expect(rootComponentInstance.myGet()).to.equal(':MYSET')

		it 'should respond correctly to an action from a scoped creator', ->
			store.dispatch(rootComponentInstance.setValue( { hello: 'world'} ))
			expect(rootComponentInstance.getValue()).to.deep.equal( { hello: 'world'} )
			store.dispatch(rootComponentInstance.mySet())
			expect(store.getState()).to.deep.equal( 42 )
