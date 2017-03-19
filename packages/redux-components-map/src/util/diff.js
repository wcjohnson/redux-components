import metadataSymbol from './metadataSymbol'
import identityReducer from 'nanotools/lib/identityReducer'
import { createComponent } from 'redux-components'

// Diff algorithm to produce dynamic reducers.
export default function diff(typeMap, metadata) {
  var k
  var componentMap = this.componentMap, reducerMap = this.reducerMap

  if( !metadata ) return

  if(this.__reentrancyGuard)
    throw new Error("Reentrant modification of a ComponentMap instance was detected.")
  this.__reentrancyGuard = true

  // Step 1: Determine which components were removed or added.
  var removed = [], added = []
  for(k in componentMap) {
    if( !(k in metadata) && (k !== metadataSymbol) ) removed.push(k)
  }
  for(k in metadata) {
    if( !(k in componentMap) && (k !== metadataSymbol) ) added.push(k)
  }
  // no-op check
  if( (added.length === 0) && (removed.length === 0) ) {
    delete this.__reentrancyGuard
    return
  }
  // Step 2:
  // Don't delete the `removed` nodes from the state tree yet, because we haven't called `willUnmount` on them.
  // Wrinkle: `willUnmount` is allowed to dispatch actions which the reducer will see.
  // So: Mount a *temporary* reducer using `combineReducers()` but with the identity attached at each `added` node.
  // However, We only need the temporary reducer if some nodes were both added AND removed.
  if( (added.length > 0) && (removed.length > 0) ) {
    added.forEach( k => reducerMap[k] = identityReducer )
    this.updateReducer()
  }
  // Step 3: Unmount removed nodes, then delete them from internal data structures
  if( removed.length > 0 ) {
    removed.forEach( k => componentMap[k].__willUnmount() )
    removed.forEach( k => { delete reducerMap[k]; delete componentMap[k] } )
  }
  // # Step 4: Instantiate the added components
  added.forEach( k => {
    var componentDescriptor = typeMap(metadata[k])
    if(!componentDescriptor) {
      throw new Error(`ComponentMap: typeMap entry not found for ComponentMap entry with key ${k}`)
    }
    componentMap[k] = createComponent(componentDescriptor)
  })
  // # Step 5: willMount the added components
  added.forEach( k => {
    var nextPath = this.path.slice()
    nextPath.push(k)
    componentMap[k].__willMount(this.store, nextPath, this)
  })
  // # Step 6: Build the "real" reducer out of the reducers of all the components that now exist.
  for(k in componentMap) {
    reducerMap[k] = componentMap[k].reducer
  }
  this.updateReducer()
  // # Step 7: Run didMount on the added components
  added.forEach( k => componentMap[k].__didMount() )

  delete this.__reentrancyGuard
}
