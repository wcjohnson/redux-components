import ReduxComponent from 'redux-components/lib/ReduxComponent'
import withSubtree from 'redux-components/lib/decorators/withSubtree'
import action from 'redux-components/lib/decorators/action'
import ComponentMap from 'redux-components-map'
import cuid from 'cuid'

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

    // API: get(i)
    // Get the i'th entry in the list
    get(i) {
      if(i >= 0 && i < this.state.list.length)
        return this._map.get(this.state.list[i])
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
      return this.state.list.length;
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
      for (var i = 0; i < this.length; i++)
        result.push(callback.call(thisArg, this.get(i), i, this))
      return result
    }
  }) // class ComponentList
}
