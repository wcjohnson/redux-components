import { expect } from 'chai';

import { mountRootComponent, ReduxComponent, decorate, action, selector } from '..';
import { makeAStore } from './helpers/store';

describe('ES classes from JS:', function() {
	var store, Subcomponent, rootComponentInstance

	it('should create class', function() {
		class IntSubcomponent extends ReduxComponent {
			reducer(state = {}, action) {
				switch(action.type) {
					case this.SET:
					return action.payload || {}
					default:
					return state
				}
			}

			setValue(val) {
				return { type: this.SET, payload: val }
			}

			getValue(state) { return state }
			amIBound() { return this.SET }
		}
		IntSubcomponent.verbs = ['SET']
		decorate(IntSubcomponent, {
			setValue: action(),
			getValue: selector(),
			amIBound: selector()
		})
		Subcomponent = IntSubcomponent
	})

	it('should mount instance of class', function() {
		store = makeAStore()
		rootComponentInstance = new Subcomponent()
		expect(rootComponentInstance.isMounted()).to.not.be.ok
		mountRootComponent(store, rootComponentInstance)
		expect(rootComponentInstance.isMounted()).to.be.ok
	})

	it('should scope everything', () => {
		expect(rootComponentInstance.SET).to.equal(':SET')
		expect(rootComponentInstance.amIBound()).to.equal(':SET')
		store.dispatch(rootComponentInstance.setValue( { hello: 'world'} ))
		expect(store.getState()).to.deep.equal( { hello: 'world'} )
		expect(rootComponentInstance.getValue()).to.deep.equal( { hello: 'world'} )
	})
})
