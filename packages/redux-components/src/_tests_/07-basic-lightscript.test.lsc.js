import { expect } from 'chai'
import { inspect } from 'util'
import { mountRootComponent, ReduxComponent, action, selector } from '..'
import { makeAStore } from './helpers/store'

describe('basic tests', ->
  var BaseComponent, Subcomponent, treeRoot, store

  describe('basic component', ->
    it('should create class and mount', ->
      now BaseComponent = class extends ReduxComponent {
        constructor() ->
          super()
          this.someInternalState = 31337

        static verbs = ['SCOPED_SET']

        reducer(state = {}, action) ->
          switch(action.type) {
            case 'SET':
              return action.payload || {}
            case this.SCOPED_SET:
              return action.payload || {}
            default:
              return state
          }

        @action()
        plainSet(value) -> ({ type: 'SET', payload: value })

        @action({ withDispatcher: 'doSetWithDispatcher' })
        setWithDispatcher(value) -> ({ type: 'SET', payload: value })

        @action({ isDispatcher: true })
        iAmADispatcher() -> ({ type: this.SCOPED_SET, payload: this.someInternalState })

        @selector()
        getValue(state) -> state

        @selector()
        getInternalValue() -> this.someInternalState
      }

      now store = makeAStore()
      now treeRoot = new BaseComponent
      expect(treeRoot.isMounted()).to.not.be.ok
      mountRootComponent(store, treeRoot)
      expect(treeRoot.isMounted()).to.be.ok
    )

    it('should log the component to the console', => console.log(inspect(treeRoot)) )

    it('should know about stores and states', => {
      expect(treeRoot.store).to.equal(store)
      expect(treeRoot.path).to.deep.equal([])
      expect(store.getState()).to.deep.equal({})
      expect(treeRoot.state).to.deep.equal({})
    })

    it('should respond to various actions', => {
      store.dispatch({type: 'SET', payload: 42})
      expect(treeRoot.state).to.equal(42)
      store.dispatch(treeRoot.plainSet(43))
      expect(treeRoot.state).to.equal(43)
      store.dispatch(treeRoot.setWithDispatcher(44))
      expect(treeRoot.state).to.equal(44)
      treeRoot.doSetWithDispatcher(45)
      expect(treeRoot.state).to.equal(45)
      treeRoot.iAmADispatcher()
      expect(treeRoot.state).to.equal(31337)
    })

    it('should work with selectors', => {
      treeRoot.doSetWithDispatcher(42)
      expect(treeRoot.getValue()).to.equal(42)
      expect(treeRoot.getInternalValue()).to.equal(31337)
    })
  )

  describe('extends', () => {
    it('should create subclass and mount', () => {
      now Subcomponent = class extends BaseComponent {
        static verbs = ['SUB_SCOPED_SET']

        reducer(state = {}, action) {
          switch(action.type) {
            case this.SUB_SCOPED_SET:
              return action.payload || {}
            default:
              return super.reducer(state, action)
          }
        }

        @action({ isDispatcher: true })
        fromSubcomponent() {
          return { type: this.SCOPED_SET, payload: 90210 }
        }

        @action({ isDispatcher: true })
        iAmADispatcher() {
          return { type: this.SUB_SCOPED_SET, payload: 58008 }
        }

        @selector()
        getValue(state) {
          return state + 1
        }
      }

      now store = makeAStore()
      now treeRoot = new Subcomponent
      expect(treeRoot.isMounted()).to.not.be.ok
      mountRootComponent(store, treeRoot)
      expect(treeRoot.isMounted()).to.be.ok
    })

    it('should log the component to the console', () => {
      console.log(inspect(treeRoot))
    })

    it('should know about stores and states', () => {
      expect(treeRoot.store).to.equal(store)
      expect(treeRoot.path).to.deep.equal([])
      expect(store.getState()).to.deep.equal({})
      expect(treeRoot.state).to.deep.equal({})
    })

    it('should respond to various actions', () => {
      store.dispatch(treeRoot.setWithDispatcher(44))
      expect(treeRoot.state).to.equal(44)
      treeRoot.doSetWithDispatcher(45)
      expect(treeRoot.state).to.equal(45)
      treeRoot.iAmADispatcher()
      expect(treeRoot.state).to.equal(58008)
      treeRoot.fromSubcomponent()
      expect(treeRoot.state).to.equal(90210)
    })

    it('should work with selectors', () => {
      treeRoot.fromSubcomponent()
      expect(treeRoot.getValue()).to.equal(90211)
      expect(treeRoot.getInternalValue()).to.equal(31337)
    })
  })
)
