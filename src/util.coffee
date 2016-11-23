export assign = (dst, src) ->
	(if src.hasOwnProperty(k) then dst[k] = src[k]) for k of src; dst

export chain = (one, two) -> -> one.apply(@, arguments); two.apply(@, arguments)

export get = (object, path) ->
	index = 0; length = path.length
	while object? and index < length
		object = object[path[index++]]
	if (index is length) then object else undefined

export removeFromList = (list, value) ->
	if (i = list.indexOf(value)) > -1 then list.splice(i, 1)
