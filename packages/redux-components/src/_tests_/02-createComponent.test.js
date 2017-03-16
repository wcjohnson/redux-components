import { expect } from 'chai'
import { mountRootComponent, ReduxComponent, action, selector, createComponent } from '..'
import { makeAStore } from './helpers/store'


describe('createComponent (no subtree)', () => {
	var BaseComponent, treeRoot, store;

	describe('basic component', () => {
		it('should mount by instance', () => {
			BaseComponent = class extends ReduxComponent {
				static verbs = ['SET']

				reducer(state = {}, action) {
					switch(action.type) {
						case this.SET:
						return action.payload || {}
						default:
						return state
					}
				}

				@action({isDispatcher: true})
				set(value) {
					return { type: this.SET, payload: value }
				}

				@selector()
				getValue(state) {
					return state
				}
			}

			store = makeAStore()
			treeRoot = createComponent(new BaseComponent)
			expect(treeRoot.isMounted()).to.not.be.ok
			mountRootComponent(store, treeRoot)
			expect(treeRoot.isMounted()).to.be.ok
			expect(treeRoot.store).to.equal(store)
			expect(treeRoot.path).to.deep.equal([])
			expect(store.getState()).to.deep.equal({})
			expect(treeRoot.state).to.deep.equal({})
			treeRoot.set(42)
			expect(treeRoot.getValue()).to.equal(42)
		})

		it('should mount with auto-new', () => {
			store = makeAStore()
			treeRoot = createComponent(BaseComponent)
			expect(treeRoot.isMounted()).to.not.be.ok
			mountRootComponent(store, treeRoot)
			expect(treeRoot.isMounted()).to.be.ok
			expect(treeRoot.store).to.equal(store)
			expect(treeRoot.path).to.deep.equal([])
			expect(store.getState()).to.deep.equal({})
			expect(treeRoot.state).to.deep.equal({})
			treeRoot.set(42)
			expect(treeRoot.getValue()).to.equal(42)
		})

		it('should mount with plain reducers', () => {
			store = makeAStore()
			treeRoot = createComponent( (state = {}, action) => {
				switch(action.type) {
					case 'SET':
					return action.payload || {}
					default:
					return state
				}
			})
			expect(treeRoot.isMounted()).to.not.be.ok
			mountRootComponent(store, treeRoot)
			expect(treeRoot.isMounted()).to.be.ok
			expect(treeRoot.store).to.equal(store)
			expect(treeRoot.path).to.deep.equal([])
			expect(store.getState()).to.deep.equal({})
			expect(treeRoot.state).to.deep.equal({})
			store.dispatch({type: 'SET', payload: 42})
			expect(treeRoot.state).to.equal(42)
		})

		it('should fail 1', () => {
			expect( () => createComponent(null) ).to.throw('invalid component descriptor')
		})
		it('should fail 2', () => {
			expect( () => createComponent(42) ).to.throw('invalid component descriptor')
			expect( () => createComponent("hello") ).to.throw('invalid component descriptor')
			expect( () => createComponent([42]) ).to.throw('invalid component descriptor')
		})
	})
})
