import { ReduxComponent, selector, action } from 'redux-components'

export default class MapMetadata extends ReduxComponent {
  static verbs = [ 'MAP_ADD', 'MAP_REMOVE', 'MAP_BULK' ]

  reducer(state = {}, action) {
    var tmp, k
    switch(action.type) {
      case this.MAP_ADD:
        tmp = {}; tmp[action.payload.key] = action.payload.descriptor
        return Object.assign({}, state, tmp)

      case this.MAP_REMOVE:
        tmp = Object.assign({}, state)
        delete tmp[action.payload]
        return tmp

      case this.MAP_BULK:
        tmp = Object.assign({}, state)
        if(action.payload.remove) {
          for(k in action.payload.remove) delete tmp[k]
        }
        if(action.payload.add) {
          for(k in action.payload.add) tmp[k] = action.payload.add[k]
        }
        return tmp

      default:
        return state
    }
  }

  @selector({isObservable: true})
  getMetadata(state) {
    return state
  }

  @action({isDispatcher: true})
  add(key, descriptor) {
    return { type: this.MAP_ADD, payload: { key: key, descriptor: descriptor} }
  }

  @action({isDispatcher: true})
  remove(key) {
    return { type: this.MAP_REMOVE, payload: key }
  }

  @action({isDispatcher: true})
  bulk(add, remove) {
    return { type: this.MAP_BULK, payload: { add: add, remove: remove} }
  }
}
