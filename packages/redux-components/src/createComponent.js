import ReduxComponent from './ReduxComponent'
import withSubtree from './decorators/withSubtree'

function createTreeComponent(shape) {
	var clazz = withSubtree(() => shape)(ReduxComponent)
	return new clazz()
}

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
		result.reducer = descriptor.bind(result)
		return result
	} else if ( (typeof descriptor === 'object') && (!!descriptor) && (!Array.isArray(descriptor)) ) {
		// Subtree descriptor -- wrap in subtree
		return createTreeComponent(descriptor)
	} else {
		throw new Error('invalid component descriptor')
	}
}
