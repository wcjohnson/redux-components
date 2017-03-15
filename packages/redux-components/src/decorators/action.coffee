import createMemoizingGetter from 'nanotools/lib/createMemoizingGetter'

getActionDispatcherDescriptor = (proto, key, actionCreator) ->
	actionDispatcher = (args...) ->
		@store.dispatch(actionCreator.call(this, args...))

	{
		configurable: true
		get: createMemoizingGetter(proto, key, actionDispatcher, -> actionDispatcher.bind(this))
	}

defineActionDispatcher = (proto, key, actionCreator) ->
	Object.defineProperty(proto, key, getActionDispatcherDescriptor(proto, key, actionCreator))

export default action = (opts) ->
	if opts then { withDispatcher, isDispatcher } = opts

	(proto, key, descriptor) ->
		originalActionCreator = descriptor.value

		if typeof originalActionCreator isnt 'function'
			throw new Error("redux-components: @action decorator (applied to #{proto.constructor?.name}.#{key}) can only be applied to action creators.")

		if isDispatcher
			# Only create a dispatcher.
			getActionDispatcherDescriptor(proto, key, originalActionCreator)
		else
			# Create an additional action dispatcher if called for
			if withDispatcher then defineActionDispatcher(proto, withDispatcher, originalActionCreator)

			# At first call, bind the action.
			{
				configurable: true
				get: createMemoizingGetter(proto, key, originalActionCreator, -> originalActionCreator.bind(this))
			}
