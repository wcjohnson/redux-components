{ inspect } = require 'util'

{ expect, assert } = require 'chai'
{ createStore } = require 'redux'

createClass = require '../createClass'
mountComponent = require '../mountComponent'
SubtreeMixin = require '../SubtreeMixin'
createComponent = require '../createComponent'

describe 'subtree: ', ->
	makeAStore = -> createStore( (x) -> x )
	store = makeAStore()

	RootComponent = null
	Subcomponent = null
	rootComponentInstance = null

	describe 'simple: ', ->
		it 'should create subcomponent class', ->
			Subcomponent = createClass {
				displayName: 'Subcomponent'
				verbs: ['SET']
				componentWillMount: ->
					console.log "Subcomponent.willMount"
				componentDidMount: ->
					console.log "Subcomponent.didMount"
				getReducer: -> (state = {}, action) ->
					switch action.type
						when @SET then action.payload or {}
						else state
				actionCreators: {
					setValue: (val) -> { type: @SET, payload: val }
				}
				selectors: {
					getValue: (state) -> state
				}
			}

		it 'should create new store', ->
			store = makeAStore()

		it 'should mount subcomponent using direct syntax', ->
			rootComponentInstance = createComponent( { foo: Subcomponent } )
			mountComponent(store, rootComponentInstance)

	describe 'complex: ', ->
		it 'should create new store', ->
			store = makeAStore()

		it 'should create root component class', ->
			RootComponent = createClass {
				displayName: 'RootComponent'
				mixins: [ SubtreeMixin ]
				componentWillMount: ->
					console.log "RootComponent.willMount"
				componentDidMount: ->
					console.log "RootComponent.didMount"
				getSubtree: -> {
					foo: new Subcomponent()
					bar: Subcomponent
					baz: -> Subcomponent
					quux: (state = {}, action) -> action?.payload or state
					deep: {
						zazz: Subcomponent
					}
				}
			}

		it 'should instantiate root component class', ->
			rootComponentInstance = new RootComponent()

		it 'should mount root instance on store', ->
			mountComponent(store, rootComponentInstance)

		it 'should print the whole component tree for your viewing pleasure', ->
			console.log(inspect(rootComponentInstance))

		it 'should respect plain reducers', ->
			store.dispatch({type: 'NONSENSE', payload: 'quux'})
			expect(rootComponentInstance.state.quux).to.equal('quux')

		it 'should instantiate class keys on subtree', ->
			assert(not(Subcomponent instanceof Subcomponent))
			assert(rootComponentInstance.bar instanceof Subcomponent)

		it 'should hoist functional subtree descriptors', ->
			assert(rootComponentInstance.baz instanceof Subcomponent)

		it 'should scope actions and selectors', ->
			store.dispatch(rootComponentInstance.foo.setValue('foo'))
			store.dispatch(rootComponentInstance.bar.setValue('bar'))
			store.dispatch(rootComponentInstance.baz.setValue('baz'))
			store.dispatch(rootComponentInstance.deep.zazz.setValue('deep.zazz'))
			expect(rootComponentInstance.foo.getValue()).to.equal('foo')
			expect(rootComponentInstance.bar.getValue()).to.equal('bar')
			expect(rootComponentInstance.baz.getValue()).to.equal('baz')
			expect(rootComponentInstance.deep.zazz.getValue()).to.equal('deep.zazz')
