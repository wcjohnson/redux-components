{ inspect } = require 'util'

{ expect, assert } = require 'chai'
{ createClass, mountRootComponent, createComponent, ObservableSelectorMixin } = require '..'
{ makeAStore } = require './helpers/store'

expectTestSequence = (tests) ->
	i = 0
	{
		next: (x) -> expect(tests[i++]?(x)).to.equal(true)
		error: (x) -> throw x
		complete: -> expect(i).to.equal(tests.length)
	}

describe 'observable selectors: ', ->
	store = makeAStore()

	RootComponent = null
	Subcomponent = null
	rootComponentInstance = null

	describe 'simple: ', ->
		it 'should create subcomponent class', ->
			Subcomponent = createClass {
				mixins: [ ObservableSelectorMixin ]
				displayName: 'Subcomponent'
				verbs: ['SET']
				componentWillMount: ->
					console.log "Subcomponent.willMount: initial state", @state
				componentDidMount: ->
					console.log "Subcomponent.didMount"
				getReducer: (currentState) ->
					(state = {}, action) ->
						switch action.type
							when @SET then Object.assign({}, state, { payload: action.payload or {} })
							else state
				actionDispatchers: {
					setValue: (val) -> { type: @SET, payload: val }
				}
				selectors: {
					getValue: (state) ->
						state.payload
				}
			}

		it 'should create new store', ->
			store = makeAStore({ foo: { payload: 'bar' } })

		it 'should mount subcomponent', ->
			rootComponentInstance = createComponent( { foo: Subcomponent } )
			mountRootComponent(store, rootComponentInstance)

		it 'should print the whole component tree for your viewing pleasure', ->
			console.log(inspect(rootComponentInstance))

		it 'should observe after mutation by an action', ->
			subscription = rootComponentInstance.foo.getValue.subscribe(
				expectTestSequence([ ((x) -> x is 'bar'), ((x) -> x is 'hello world')] )
			)
			rootComponentInstance.foo.setValue('hello world')
			subscription.unsubscribe()

		it 'should unsubscribe', ->
			subscription = rootComponentInstance.foo.getValue.subscribe(
				expectTestSequence([ ((x) -> x is 'hello world'), ((x) -> x is 'goodbye world')] )
			)
			rootComponentInstance.foo.setValue('goodbye world')
			subscription.unsubscribe()
			rootComponentInstance.foo.setValue('bar')
