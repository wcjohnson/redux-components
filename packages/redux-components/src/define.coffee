import applyLegacyPropertyDecorator from 'nanotools/lib/applyLegacyPropertyDecorator'

export default define = (constr, definitions) ->
	proto = constr.prototype
	for k,v of definitions
		applyLegacyPropertyDecorator(proto, k, v)
	return
