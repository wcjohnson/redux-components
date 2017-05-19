import ReduxComponent from 'redux-components/lib/ReduxComponent'
import withSubtree from 'redux-components/lib/decorators/withSubtree'
import action from 'redux-components/lib/decorators/action'
import selector from 'redux-components/lib/decorators/selector'
import ComponentMap from 'redux-components-map'
import cuid from 'cuid'
import createBehaviorSubject from 'observable-utils/lib/createBehaviorSubject'

export default function ComponentList(typeMap) {
  // Support objects as typemaps
  if(typeof typeMap !== 'function') {
    var typeMapObject = typeMap
    typeMap = key => typeMapObject[key]
  }
  var ComponentMapClass = ComponentMap(typeMap)

  return withSubtree(() => ({
    _map: ComponentMapClass
  }))(class ComponentList extends ReduxComponent {
    static verbs = ['INTERNAL_SPLICE']

    constructor() {
      super()

      // toArray observable
      // TODO: clean this up somehow
      var subj = createBehaviorSubject()
      this._internalList.subscribe({
        next: () => subj.next(this.toArray())
      })
      var myToArray = this.toArray
      var nextToArray = function() {
        return myToArray.call(this);
      }
      Object.assign(nextToArray, subj)
      this.toArray = nextToArray
    }

    reducer(state, action) {
      // Initial state
      if (!state.list) state = Object.assign({}, state, { list: [] })
      switch (action.type) {
        case this.INTERNAL_SPLICE:
          var nextArray = state.list.slice()
          nextArray.splice(...action.payload)
          return Object.assign({}, state, { list: nextArray })
        default:
          return state
      }
    }

    @action({isDispatcher: true})
    _internalAdd(index, ...additions) {
      return {
        type: this.INTERNAL_SPLICE,
        payload: [index, 0, ...additions]
      }
    }

    @action({isDispatcher: true})
    _internalRemove(index, n) {
      return {
        type: this.INTERNAL_SPLICE,
        payload: [index, n]
      }
    }

    @selector({isObservable: true})
    _internalList(state) {
      return state.list || []
    }

    // API: get(i)
    // Get the i'th entry in the list
    get(i) {
      var list = this.state.list
      if (!list) return undefined
      if(i >= 0 && i < list.length)
        return this._map.get(list[i])
    }

    // API: toArray()
    // Convert to a plain JS array of ReduxComponents
    toArray() {
      return this.map(x => x)
    }

    // API: splice(index, howmany, ...descriptors)
    // As `array.splice` but does not take negative indices or return
    // removed entities.
    splice(index, howmany, ...descriptors) {
      if (index < 0) throw new Error("ComponentList.splice: positive indices only")
      var list = this.state.list

      var removals = null;
      if (howmany > 0) {
        removals = list.slice(index, index + howmany)
        // Remove from local array first
        this._internalRemove(index, howmany)
        // Unmount from map
        removals.forEach((id) => this._map.remove(id))
      }

      if (descriptors.length > 0) {
        // Add to map first
        var ids = descriptors.map(() => cuid())
        ids.forEach((id, idx) => this._map.add(id, descriptors[idx]))
        // Then add to local array
        this._internalAdd(index, ...ids)
      }
    }

    get length() {
      var state = this.state
      if (!state) return 0
      return state.list.length
    }

    // API: push(...descriptors)
    // Add a new component with the given descriptor to the end of the list
    push(...descriptors) {
      this.splice(this.length, 0, ...descriptors)
    }

    // API: unshift(...descriptors)
    // Add a new component with the given descriptor to the beginning of the list
    unshift(...descriptors) {
      this.splice(0, 0, ...descriptors)
    }

    // API: forEach(callback, thisArg)
    forEach(callback, thisArg) {
      for (var i = 0; i < this.length; i++)
        callback.call(thisArg, this.get(i), i, this)
    }

    // API: map(callback, thisArg)
    map(callback, thisArg) {
      var result = []
      var state = this.state
      if (!state || !state.list) return result
      var list = state.list
      for (var i = 0; i < list.length; i++)
        result.push(callback.call(thisArg, this._map.get(list[i]), i, this))
      return result
    }
  }) // class ComponentList
}
