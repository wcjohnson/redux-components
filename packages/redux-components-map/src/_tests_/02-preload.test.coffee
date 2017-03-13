{ expect } = require 'chai'

{ createClass, mountRootComponent, createComponent } = require 'redux-components'
{ makeAStore, testComponentMixin } = require './helpers/store'
{ ComponentMap } = require '..'

describe 'preloading unmounted ComponentMap: ', ->
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
			MapClass = ComponentMap( { SubcomponentOne, SubcomponentTwo } )
			rootComponentInstance = new MapClass()

		it 'should mount instance of class on store', ->
			rootComponentInstance.add('one', 'SubcomponentOne')
			rootComponentInstance.add('two', 'SubcomponentTwo')
			rootComponentInstance.remove('two')
			mountRootComponent(store, rootComponentInstance)
			expect(rootComponentInstance.get('one').get()).to.equal('mounted')
			expect(rootComponentInstance.get('two')).to.not.be.ok
