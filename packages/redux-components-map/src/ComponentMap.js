import combineReducers from 'nanotools/lib/combineReducers'
import identityReducer from 'nanotools/lib/identityReducer'
import invariant from 'nanotools/lib/invariant'
import DynamicReducerComponent from 'redux-components/lib/DynamicReducerComponent'
import MapMetadata from './util/MapMetadata'
import diff from './util/diff'
import metadataSymbol from './util/metadataSymbol'

export default function ComponentMap(typeMap) {
  // Support objects as typemaps
  if(typeof typeMap !== 'function') {
    var typeMapObject = typeMap
    typeMap = key => typeMapObject[key]
  }

  return class ComponentMap extends DynamicReducerComponent {
    constructor() {
      super()
      this.metadata = new MapMetadata()
    }

    updateReducer() {
      this.replaceReducer(combineReducers(this.reducerMap))
    }

    componentWillMount() {
      if(super.componentWillMount) { super.componentWillMount() }
      this.reducerMap = Object.create(null)
      this.reducerMap[metadataSymbol] = this.metadata.reducer
      this.componentMap = Object.create(null)
      // Mount the metadata node.
      this.metadata.__willMount(this.store, this.path.concat([metadataSymbol]), this)
      this.updateReducer()
    }

    componentDidMount() {
      if(this.preMount) {
        this.metadata.bulk(this.preMount)
        delete this.preMount
      }
      // Diff whenever metadata changes.
      this.subscription = this.metadata.getMetadata.subscribe({
        next: (metadata) => diff.call(this, typeMap, metadata)
      })
    }

    componentWillUnmount() {
      // Unsub from observer
      if(this.subscription) {
        this.subscription.unsubscribe()
        delete this.subscription
      }
      // Unmount subcomponents
      for(var k in this.componentMap) {
        var v = this.componentMap[k]
        v.__willUnmount()
      }
      this.metadata.__willUnmount()
      this.replaceReducer(identityReducer)
      delete this.componentMap
      delete this.reducerMap
    }

    // API: get(key)
    // Retrieve a component by key from the map.
    get(key) {
      if(process.env.NODE_ENV !== 'production') {
        invariant(this.componentMap, `Illegal call to ComponentMap.get() on an unmounted ComponentMap.`)
      }
      return this.componentMap[key]
    }

    // API: keys()
    // Retrieve an array consisting of all keys of the map.
    keys() {
      return Object.keys(this.componentMap)
    }

    // API: forEach(callback, thisArg)
    // Iterate the map, like `Map.forEach`
    forEach(callback, thisArg) {
      if(thisArg) {
        for(var k in this.componentMap) {
          callback.call(thisArg, this.componentMap[k], k, this)
        }
      } else {
        for(k in this.componentMap) {
          callback(this.componentMap[k], k, this)
        }
      }
    }

    // API: has(key)
    has(key) {
      if( this.componentMap[key] ) return true; else return false
    }

    // API: add(key, descriptor)
    add(key, descriptor) {
      if(this.isMounted()) {
        if(key in this.componentMap) throw new Error(`duplicate key "${key}" in ComponentMap`)
        this.metadata.add(key, descriptor)
      } else {
        if( !(this.preMount) ) this.preMount = {}
        this.preMount[key] = descriptor
      }
    }

    // API: remove(key)
    remove(key) {
      if(this.isMounted()) {
        this.metadata.remove(key)
      } else {
        if(this.preMount) delete this.preMount[key]
      }
    }

  } // class ComponentMap
}
