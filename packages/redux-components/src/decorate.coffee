import applyLegacyPropertyDecorator from 'nanotools/lib/applyLegacyPropertyDecorator'

export default decorate = (constr, definitions) ->
	proto = constr.prototype
	for k,v of definitions
		if Array.isArray(v)
			applyLegacyPropertyDecorator(proto, k, x) for x in v
		else
			applyLegacyPropertyDecorator(proto, k, v)
	return
