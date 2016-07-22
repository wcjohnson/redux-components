"use strict"
_export = null

assign = (dst, src) -> (if src.hasOwnProperty(k) then dst[k] = src[k]) for k of src; dst

chain = (one, two) -> -> one.apply(@, arguments); two.apply(@, arguments)

get = (object, path) ->
	index = 0; length = path.length
	while object? and index < length
		object = object[path[index++]]
	if (index is length) then object else undefined

_export = { assign, chain, get }
module.exports = _export
