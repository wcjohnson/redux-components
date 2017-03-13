{ expect } = require 'chai'

{ createClass, mountRootComponent, createComponent } = require 'redux-components'
{ makeAStore, testComponentMixin } = require './helpers/store'
{ ComponentMap } = require '..'

describe 'basic functions: ', ->
	store = makeAStore()

	SubcomponentOne = null
	SubcomponentTwo = null
	MapClass = null
	rootComponentInstance = null

	describe 'trivial map: ', ->
		it 'should create fresh store', ->
			store = makeAStore()

		it 'should create component class', ->
			SubcomponentOne = createClass {
				displayName: 'SubcomponentOne'
				mixins: [ testComponentMixin ]
			}
			SubcomponentTwo = createClass {
				displayName: 'SubcomponentTwo'
				mixins: [ testComponentMixin ]
			}

		it 'should create ComponentMap with typemap', ->
			typeMap = { SubcomponentOne, SubcomponentTwo }
			MapClass = ComponentMap( (desc) -> typeMap[desc] )

		it 'should mount instance of class on store', ->
			rootComponentInstance = new MapClass()
			mountRootComponent(store, rootComponentInstance)

		it 'should mount component 1', ->
			rootComponentInstance.add('one', 'SubcomponentOne')
			expect(rootComponentInstance.get('one').get()).to.equal('mounted')

		it 'should error on duplicate key', ->
			expect ->
				rootComponentInstance.add('one', 'SubcomponentOne')
			.to.throw("duplicate key `one` in ComponentMap")

		it 'should mount component 2', ->
			rootComponentInstance.add('two', 'SubcomponentTwo')
			expect(rootComponentInstance.get('two').get()).to.equal('mounted')

		it 'should exercise mounted components', ->
			rootComponentInstance.get('one').set('hello')
			expect(rootComponentInstance.get('one').get()).to.equal('hello')
			rootComponentInstance.get('two').set('world')
			expect(rootComponentInstance.get('two').get()).to.equal('world')

		it 'should unmount component 1', ->
			rootComponentInstance.remove('one')
			expect(rootComponentInstance.get('one')).to.not.be.ok

		it 'should do nothing on double removal', ->
			rootComponentInstance.remove('one')

		it 'should flush component 1 data after a reduction that would change the store', ->
			rootComponentInstance.get('two').set('next')
			expect(rootComponentInstance.state.one).to.not.be.ok
