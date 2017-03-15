import { expect } from 'chai'
import { mountRootComponent, ReduxComponent } from 'redux-components'
import { makeAStore } from './helpers/store';
import action from '../action'

describe('bind decorator', () => {
	it('should work', () => {
		class Test extends ReduxComponent {
			static verbs = ['SET']

			getReducer() {
				return (state = {}, action) => {
					switch(action.type) {
						case this.SET:
						return action.payload || {}
						default:
						return state
					}
				}
			}

			@action({withDispatcher: 'setValue'})
			setValueAction(val) { return { type: this.SET, payload: val } }
		}

		let store = makeAStore()
		let rootComponentInstance = new Test()
		expect(rootComponentInstance.isMounted()).to.not.be.ok
		mountRootComponent(store, rootComponentInstance)
		expect(rootComponentInstance.isMounted()).to.be.ok
		rootComponentInstance.setValue(3)
	})
})
