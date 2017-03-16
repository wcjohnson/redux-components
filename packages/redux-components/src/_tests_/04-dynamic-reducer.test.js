import { expect } from 'chai'
import { mountRootComponent, ReduxComponent, action, selector, DynamicReducerComponent } from '..'
import { makeAStore } from './helpers/store'

describe('dynamic reducer', () => {
	var BaseComponent, treeRoot, store;

	it('should initialize', () => {
		BaseComponent = class extends DynamicReducerComponent {
			static verbs = ['CHANGE_MAGIC_WORD']

			getInitialState() {
				return { magicWord: 'please' }
			}

			componentWillMount() {
				this._subscription = this.whatsTheMagicWord.subscribe({
					next: (val) => {
						console.log("observer saw", val)
						this.replaceReducer( (state, action) => {
							switch(action.type) {
								case val:
									return Object.assign({}, state, { gotTheMagicWord: true })
								case this.CHANGE_MAGIC_WORD:
									return Object.assign({}, state, { magicWord: action.payload })
								default:
									return state
							}
						})
					}
				})
			}

			componentWillUnmount() {
				if(this._subscription) {
					this._subscription.unsubscribe()
					delete this._subscription
				}
			}

			@selector({isObservable: true})
			whatsTheMagicWord(state) {
				return state.magicWord
			}

			@action({isDispatcher: true})
			changeTheMagicWord(value) {
				return { type: this.CHANGE_MAGIC_WORD, payload: value }
			}

			@action({isDispatcher: true})
			sayTheMagicWord() {
				return { type: this.state.magicWord }
			}
		}
	})

	it('should behave nondynamically', () => {
		store = makeAStore()
		treeRoot = new BaseComponent
		mountRootComponent(store, treeRoot)
		expect(treeRoot.state.gotTheMagicWord).to.not.be.ok
		treeRoot.sayTheMagicWord()
		expect(treeRoot.state.gotTheMagicWord).to.be.ok
	})

	it('should behave dynamically', () => {
		store = makeAStore()
		treeRoot = new BaseComponent
		mountRootComponent(store, treeRoot)
		expect(treeRoot.state.gotTheMagicWord).to.not.be.ok
		treeRoot.changeTheMagicWord('plz')
		treeRoot.sayTheMagicWord()
		expect(treeRoot.state.gotTheMagicWord).to.be.ok
	})
})
