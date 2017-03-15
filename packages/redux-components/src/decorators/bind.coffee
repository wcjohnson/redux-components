import createMemoizingGetter from 'nanotools/lib/createMemoizingGetter'

export default bind = (proto, key, descriptor) ->
	fn = descriptor.value

	if typeof fn isnt 'function'
		throw new Error("@bind decorator (applied to #{proto.constructor?.name}.#{key}) can only be applied to functions.")

	{
		configurable: true
		get: createMemoizingGetter(proto, key, fn, -> fn.bind(this))
	}
