import applyLegacyPropertyDecorator from 'nanotools/lib/applyLegacyPropertyDecorator'

export default function decorate(constr, definitions) {
	var proto, k, v
	proto = constr.prototype
	for (k in definitions) {
		v = definitions[k]
		if(Array.isArray(v)) {
			v.forEach( (x) => applyLegacyPropertyDecorator(proto, k, x) )
		} else {
			applyLegacyPropertyDecorator(proto, k, v)
		}
	}
}
