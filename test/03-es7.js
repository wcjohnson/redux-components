// Check ES7 syntax
import { ReduxComponent, createClass } from ".."
import { createStore } from "redux"

describe('es7: ', function() {
	let store, RootComponent, rootComponentInstance, Subcomponent;

	function makeAStore() {
		store = createStore( (x) => x )
	}

	it('should test es7 decorator mixin syntax', function() {
		let myMixin = (x) => x
		Subcomponent = createClass(
			@myMixin
			{
				displayName: "myClass",
				getReducer: () => (state, action) => action.payload
			}
		);
	});
});
