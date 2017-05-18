import { expect, assert } from 'chai'
import { makeAStore } from './helpers/store'
import { mountRootComponent, ReduxComponent, action, selector } from 'redux-components'
import ComponentList from '..'

class BaseComponent extends ReduxComponent {
  static verbs = ['SCOPED_SET']

  reducer(state = {}, action) {
    switch(action.type) {
      case this.SCOPED_SET:
      return action.payload || {}
      default:
      return state
    }
  }

  @action()
  plainSet(value) {
    return { type: 'SET', payload: value }
  }

  @action({ withDispatcher: 'doSetWithDispatcher' })
  setWithDispatcher(value) {
    return { type: 'SET', payload: value }
  }

  @action({ isDispatcher: true })
  set(x) { return { type: this.SCOPED_SET, payload: x } }

  @selector()
  get(state) { return state }
}

describe("basic tests", () => {

  it("should work", () => {
    var store = makeAStore()

    var MyComponentList = ComponentList(() => BaseComponent)
    var myComponentList = new MyComponentList()
    mountRootComponent(store, myComponentList)

    myComponentList.push(true)
    myComponentList.get(0).set("hi")
    myComponentList.push(true)
    myComponentList.get(1).set("world")

    assert.deepEqual(myComponentList.map((x) => x.get()), ["hi", "world"])

    myComponentList.splice(0, 1)
    assert(myComponentList.get(0).get() === "world")

  })
})
