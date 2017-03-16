import { expect } from 'chai'
import { mountRootComponent, ReduxComponent, action, selector, withSubtree, createComponent } from '..'
import { makeAStore } from './helpers/store'


describe('subtree', () => {
	var BaseComponent, DecoratedComponent, treeRoot, subBranch, store;

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
		get(state) {
			return state
		}
	}

	describe('via createComponent', () => {
		it('should create and mount', () => {
			store = makeAStore()
			subBranch = new BaseComponent
			treeRoot = createComponent({
				a: new BaseComponent,
				b: BaseComponent,
				c: (state = {}, action) => Object.assign({}, state, { action }),
				d: {
					e: subBranch,
					f: {
						g: BaseComponent
					}
				}
			})
			expect(treeRoot.isMounted()).to.not.be.ok
			mountRootComponent(store, treeRoot)
			expect(treeRoot.isMounted()).to.be.ok
			expect(treeRoot.store).to.equal(store)
			expect(treeRoot.path).to.deep.equal([])
		})

		it('should be pathaware', () => {
			expect(treeRoot.a.path).to.deep.equal(['a'])
			expect(treeRoot.a.parentComponent).to.equal(treeRoot)
			expect(treeRoot.d.e.path).to.deep.equal(['d', 'e'])
			expect(treeRoot.d.f.g.path).to.deep.equal(['d', 'f', 'g'])
			expect(treeRoot.d.f.g.parentComponent).to.equal(treeRoot.d.f)
		})

		it('should do all the things', () => {
			treeRoot.a.set(42)
			expect(treeRoot.a.get()).to.equal(42)
			expect(treeRoot.c.state.action).to.deep.equal({type: 'a:SET', payload: 42})
			treeRoot.d.f.g.set(31337)
			expect(treeRoot.d.f.g.get()).to.equal(31337)
			expect(treeRoot.c.state.action).to.deep.equal({type: 'd.f.g:SET', payload: 31337})
			subBranch.set(90210)
			expect(treeRoot.d.e.get()).to.equal(90210)
		})
	})

	describe('via decorator', () => {
		it('should remake', () => {
			subBranch = new BaseComponent

			DecoratedComponent = @withSubtree( () => ({
				a: BaseComponent,
				b: {
					c: subBranch,
					d: (state = {}, action) => Object.assign({}, state, { action })
				}
			}) )
			class extends ReduxComponent {
				reducer(state = {}, action) {
					if (action.type === 'DIDMOUNT') {
						return Object.assign({}, state, {didMount: true})
					} else {
						return Object.assign({}, state, {iSaw: action})
					}
				}

				// Test to make sure the superclass is being delegated to
				componentWillMount() {
					this.willMountRan = true
				}

				componentDidMount() {
					this.store.dispatch({type: 'DIDMOUNT'})
				}
			}
		})

		it('should create and mount', () => {
			store = makeAStore()
			treeRoot = new DecoratedComponent
			expect(treeRoot.isMounted()).to.not.be.ok
			mountRootComponent(store, treeRoot)
			expect(treeRoot.willMountRan).to.be.ok
			expect(treeRoot.isMounted()).to.be.ok
			expect(treeRoot.state.didMount).to.be.ok
			expect(treeRoot.store).to.equal(store)
			expect(treeRoot.path).to.deep.equal([])
		})

		it('should be pathaware', () => {
			expect(treeRoot.a.path).to.deep.equal(['a'])
			expect(treeRoot.a.parentComponent).to.equal(treeRoot)
			expect(treeRoot.b.d.path).to.deep.equal(['b', 'd'])
			expect(treeRoot.b.d.parentComponent).to.equal(treeRoot.b)
		})

		it('should do all the things', () => {
			treeRoot.a.set(42)
			// Make sure local state is retained after subreducer
			expect(treeRoot.state.didMount).to.be.ok
			expect(treeRoot.a.get()).to.equal(42)
			expect(treeRoot.state.iSaw).to.deep.equal({type: 'a:SET', payload: 42})
			expect(treeRoot.b.d.state.action).to.deep.equal({type: 'a:SET', payload: 42})
			subBranch.set(90210)
			expect(treeRoot.b.c.get()).to.equal(90210)
		})
	})
})
