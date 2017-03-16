{ expect } = require 'chai'

{ createClass, mountRootComponent, createComponent } = require 'redux-components-legacy'
{ makeAStore, makeDevToolsStore, testComponentMixin } = require './helpers/store'
{ ComponentMap } = require '..'
{ ActionTypes: DevToolsActions } = require 'redux-devtools-instrument'

describe 'nightmare scenarios: ', ->
	store = makeAStore()

	SubcomponentOne = null
	SubcomponentTwo = null
	MapClass = null
	rootComponentInstance = null
	devToolsReducer = (state, action) -> state

	it 'should create infrastructure objects', ->
		SubcomponentOne = createClass {
			displayName: 'SubcomponentOne'
			mixins: [ testComponentMixin ]
		}
		SubcomponentTwo = createClass {
			displayName: 'SubcomponentTwo'
			mixins: [ testComponentMixin ]
		}
		SubcomponentEXPLODE = createClass (
			displayName: 'SubcomponentEXPLODE'
			mixins: [ testComponentMixin ]
			componentWillMount: ->
				rootComponentInstance.add('explosion', 'SubcomponentEXPLODE')
		)
		SubcomponentUnmount = createClass (
			displayName: 'SubcomponentUnmount'
			mixins: [ testComponentMixin ]
			componentWillUnmount: ->
				@store.dispatch({type: 'TEST_ACTION'})
		)
		typeMap = { SubcomponentOne, SubcomponentTwo, SubcomponentEXPLODE, SubcomponentUnmount }
		MapClass = ComponentMap( (desc) -> typeMap[desc] )

	describe 'rehydration: ', ->
		it 'should make a store with a rehydrated state', ->
			store = makeAStore({ '@@metadata': { one: 'SubcomponentOne', two: 'SubcomponentTwo' }, one: 'hello', two: 'world' })
		it 'should remount all components', ->
			rootComponentInstance = new MapClass()
			mountRootComponent(store, rootComponentInstance)
		it 'should have the right state', ->
			expect(rootComponentInstance.get('one').get()).to.equal('mounted')
			expect(rootComponentInstance.get('two').get()).to.equal('mounted')

	describe 'sudden state transition/time travel: ', ->
		it 'should make a devtools store', ->
			store = makeDevToolsStore(undefined, devToolsReducer)
		it 'should mount a map at the root', ->
			rootComponentInstance = new MapClass()
			mountRootComponent(store, rootComponentInstance)
		it 'should mount component 1', ->
			rootComponentInstance.add('one', 'SubcomponentOne')
			expect(rootComponentInstance.get('one').get()).to.equal('mounted')
		it 'should commit the devtools state', ->
			store.liftedStore.dispatch({type: DevToolsActions.COMMIT})
		it 'should mutate component 1', ->
			rootComponentInstance.get('one').set('mutated')
			expect(rootComponentInstance.get('one').get()).to.equal('mutated')
		it 'should mount component 2', ->
			rootComponentInstance.add('two', 'SubcomponentTwo')
			expect(rootComponentInstance.get('two').get()).to.equal('mounted')
		it 'should verify devtools are in the proper state', ->
			devToolsState = store.liftedStore.getState()
			expect(devToolsState.currentStateIndex).to.equal(4) # 3 actions since commit
		it 'should timetravel and unmount component 2', ->
			c2instance = rootComponentInstance.get('two')
			expect(c2instance.__mounted).to.be.ok
			store.liftedStore.dispatch({type: DevToolsActions.ROLLBACK})
			expect(c2instance.__mounted).to.not.be.ok
			expect(rootComponentInstance.keys()).to.deep.equal(['one'])
			expect(rootComponentInstance.get('one').get()).to.equal('mounted')

	describe 'reentrancy: ', ->
		it 'should make a store with a rehydrated state', ->
			store = makeAStore({ '@@metadata': { one: 'SubcomponentEXPLODE'} })
		it 'should blow up on reentrant modification of the map', ->
			rootComponentInstance = new MapClass()
			expect ->
				mountRootComponent(store, rootComponentInstance)
			.to.throw("Reentrant modification of a ComponentMap instance was detected.")

	describe 'preservation of hydrated state during mutations: ', ->
		it 'should make a store with a rehydrated state', ->
			store = makeAStore({ '@@metadata': { one: 'SubcomponentUnmount', two: 'SubcomponentTwo' }, one: 'hello', two: 'world' })
		it 'should rehydrate state', ->
			rootComponentInstance = new MapClass()
			mountRootComponent(store, rootComponentInstance)
		it 'shouldnt drop state of rehydrating components if willUnmount causes a dispatch', ->
			rootComponentInstance.bulk({ three: 'SubcomponentOne'}, { one: true })
