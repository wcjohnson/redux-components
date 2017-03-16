import ReduxComponent from './ReduxComponent'
import withSubtree from './decorators/withSubtree'

export default function createComponent(descriptor) {
	if (descriptor instanceof ReduxComponent) {
		// Just a component
		return descriptor
	} else if ( (typeof descriptor === 'function') && (descriptor.prototype instanceof ReduxComponent) ) {
		// Class of component -- instantiate
		return new descriptor()
	} else if ( typeof descriptor === 'function' ) {
		// Pure reducer function -- wrap
		var result = new ReduxComponent()
		result.reducer = descriptor
		return result
	} else if ( (typeof descriptor === 'object') && (!!descriptor) && (!Array.isArray(descriptor)) ) {
		// Subtree description -- wrap in subtree
		var clazz = withSubtree(() => descriptor)(ReduxComponent)
		return new clazz()
	} else {
		throw new Error('invalid component descriptor')
	}
}
