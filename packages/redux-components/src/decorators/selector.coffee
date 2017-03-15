import createMemoizingGetter from 'nanotools/lib/createMemoizingGetter'
import makeSelectorObservable from '../makeSelectorObservable'

augmentSelector = (selector, instance, makeObservable) ->
	boundSelector = (state, args...) -> selector.call(this, instance.state, args...)
	if makeObservable then makeSelectorObservable(instance, boundSelector) else boundSelector

export default selector = (opts) ->
	if opts then { isObservable } = opts

	(proto, key, descriptor) ->
		originalSelector = descriptor.value

		if typeof originalSelector isnt 'function'
			throw new Error("redux-components: @selector decorator (applied to #{proto.constructor?.name}.#{key}) can only be applied to selectors.")

		{
			configurable: true
			get: createMemoizingGetter(proto, key, originalSelector, -> augmentSelector(originalSelector, this, isObservable))
		}
