export chain = (one, two) -> -> one.apply(@, arguments); two.apply(@, arguments)

export get = (object, path) ->
	index = 0; length = path.length
	while object? and index < length
		object = object[path[index++]]
	if (index is length) then object else undefined

export removeFromList = (list, value) ->
	if list? and ((i = list.indexOf(value)) > -1) then list.splice(i, 1)
	undefined

export nullIdentity = (x) -> if x is undefined then null else x
