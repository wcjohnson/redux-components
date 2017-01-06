import { makeSelectorsObservable } from './makeSelectorObservable'

export default ObservableSelectorMixin = {
	componentWillMount: ->
		makeSelectorsObservable(@)
}
