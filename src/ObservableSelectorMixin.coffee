import makeSelectorObservable from './makeSelectorObservable'

export default ObservableSelectorMixin = {
	componentWillMount: ->
		if @selectors
			makeSelectorObservable(@, @[selKey]) for selKey of @selectors
		undefined
}
