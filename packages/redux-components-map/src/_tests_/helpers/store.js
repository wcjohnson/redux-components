var ReduxDebug, ReduxFreeze, applyMiddleware, compose, createStore, cuid, instrument, makeAStore, makeDevToolsStore, ref, testComponentMixin;

ref = require('redux'), createStore = ref.createStore, applyMiddleware = ref.applyMiddleware, compose = ref.compose;

ReduxDebug = require('redux-debug');

ReduxFreeze = require('redux-freeze');

instrument = (require('redux-devtools-instrument'))["default"];

cuid = require('cuid');

makeAStore = function(initialState) {
  return createStore((function(x) {
    return x;
  }), initialState, applyMiddleware(ReduxDebug(console.log), ReduxFreeze));
};

makeDevToolsStore = function(initialState, monitorReducer) {
  var enhancer;
  enhancer = compose(applyMiddleware(ReduxDebug(console.log), ReduxFreeze), instrument(monitorReducer));
  return createStore((function(x) {
    return x;
  }), initialState, enhancer);
};

testComponentMixin = {
  verbs: ['SET'],
  componentWillMount: function() {
    this.iid = cuid();
    return console.log(`${this.displayName} ${this.iid} willMount with initial state:`, this.state);
  },
  componentDidMount: function() {
    console.log(`${this.displayName} ${this.iid} didMount`);
    return this.set('mounted');
  },
  componentWillUnmount: function() {
    return console.log(`${this.displayName} ${this.iid} willUnmount`);
  },
  getReducer: function() {
    return function(state = null, action) {
      console.log(`${this.displayName} ${this.iid} reducer:`, { state: state, action: action })
      var value;
      value = (function() {
        switch (action.type) {
          case this.SET:
            return action.payload || {};
          default:
            return state;
        }
      }).call(this);
      return value;
    };
  },
  actionDispatchers: {
    set: function(x) {
      return {
        type: this.SET,
        payload: x
      };
    }
  },
  get: function() {
    return this.state;
  }
};

module.exports = {
  makeAStore: makeAStore,
  testComponentMixin: testComponentMixin,
  makeDevToolsStore: makeDevToolsStore
};
