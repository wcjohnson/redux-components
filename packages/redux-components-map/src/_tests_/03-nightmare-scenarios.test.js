var ComponentMap, DevToolsActions, createClass, createComponent, expect, makeAStore, makeDevToolsStore, mountRootComponent, ref, ref1, testComponentMixin;

expect = require('chai').expect;

ref = require('redux-components-legacy'), createClass = ref.createClass, mountRootComponent = ref.mountRootComponent, createComponent = ref.createComponent;

ref1 = require('./helpers/store'), makeAStore = ref1.makeAStore, makeDevToolsStore = ref1.makeDevToolsStore, testComponentMixin = ref1.testComponentMixin;

ComponentMap = require('..').default;

DevToolsActions = require('redux-devtools-instrument').ActionTypes;

describe('nightmare scenarios: ', function() {
  var MapClass, SubcomponentOne, SubcomponentTwo, devToolsReducer, rootComponentInstance, store;
  store = makeAStore();
  SubcomponentOne = null;
  SubcomponentTwo = null;
  MapClass = null;
  rootComponentInstance = null;
  devToolsReducer = function(state, action) {
    return state;
  };
  it('should create infrastructure objects', function() {
    var SubcomponentEXPLODE, SubcomponentUnmount, typeMap;
    SubcomponentOne = createClass({
      displayName: 'SubcomponentOne',
      mixins: [testComponentMixin]
    });
    SubcomponentTwo = createClass({
      displayName: 'SubcomponentTwo',
      mixins: [testComponentMixin]
    });
    SubcomponentEXPLODE = createClass({
      displayName: 'SubcomponentEXPLODE',
      mixins: [testComponentMixin],
      componentWillMount: function() {
        return rootComponentInstance.add('explosion', 'SubcomponentEXPLODE');
      }
    });
    SubcomponentUnmount = createClass({
      displayName: 'SubcomponentUnmount',
      mixins: [testComponentMixin],
      componentWillUnmount: function() {
        return this.store.dispatch({
          type: 'TEST_ACTION'
        });
      }
    });
    typeMap = {
      SubcomponentOne: SubcomponentOne,
      SubcomponentTwo: SubcomponentTwo,
      SubcomponentEXPLODE: SubcomponentEXPLODE,
      SubcomponentUnmount: SubcomponentUnmount
    };
    return MapClass = ComponentMap(function(desc) {
      return typeMap[desc];
    });
  });
  describe('rehydration: ', function() {
    it('should make a store with a rehydrated state', function() {
      return store = makeAStore({
        '@@metadata': {
          one: 'SubcomponentOne',
          two: 'SubcomponentTwo'
        },
        one: 'hello',
        two: 'world'
      });
    });
    it('should remount all components', function() {
      rootComponentInstance = new MapClass();
      return mountRootComponent(store, rootComponentInstance);
    });
    return it('should have the right state', function() {
      expect(rootComponentInstance.get('one').get()).to.equal('mounted');
      return expect(rootComponentInstance.get('two').get()).to.equal('mounted');
    });
  });
  describe('sudden state transition/time travel: ', function() {
    it('should make a devtools store', function() {
      return store = makeDevToolsStore(void 0, devToolsReducer);
    });
    it('should mount a map at the root', function() {
      rootComponentInstance = new MapClass();
      return mountRootComponent(store, rootComponentInstance);
    });
    it('should mount component 1', function() {
      rootComponentInstance.add('one', 'SubcomponentOne');
      return expect(rootComponentInstance.get('one').get()).to.equal('mounted');
    });
    it('should commit the devtools state', function() {
      return store.liftedStore.dispatch({
        type: DevToolsActions.COMMIT
      });
    });
    it('should mutate component 1', function() {
      rootComponentInstance.get('one').set('mutated');
      return expect(rootComponentInstance.get('one').get()).to.equal('mutated');
    });
    it('should mount component 2', function() {
      rootComponentInstance.add('two', 'SubcomponentTwo');
      return expect(rootComponentInstance.get('two').get()).to.equal('mounted');
    });
    it('should verify devtools are in the proper state', function() {
      var devToolsState;
      devToolsState = store.liftedStore.getState();
      return expect(devToolsState.currentStateIndex).to.equal(4);
    });
    return it('should timetravel and unmount component 2', function() {
      var c2instance;
      c2instance = rootComponentInstance.get('two');
      expect(c2instance.__mounted).to.be.ok;
      store.liftedStore.dispatch({
        type: DevToolsActions.ROLLBACK
      });
      expect(c2instance.__mounted).to.not.be.ok;
      expect(rootComponentInstance.keys()).to.deep.equal(['one']);
      return expect(rootComponentInstance.get('one').get()).to.equal('mounted');
    });
  });
  describe('reentrancy: ', function() {
    it('should make a store with a rehydrated state', function() {
      return store = makeAStore({
        '@@metadata': {
          one: 'SubcomponentEXPLODE'
        }
      });
    });
    return it('should blow up on reentrant modification of the map', function() {
      rootComponentInstance = new MapClass();
      return expect(function() {
        return mountRootComponent(store, rootComponentInstance);
      }).to["throw"]("Reentrant modification of a ComponentMap instance was detected.");
    });
  });
  return describe('preservation of hydrated state during mutations: ', function() {
    it('should make a store with a rehydrated state', function() {
      return store = makeAStore({
        '@@metadata': {
          one: 'SubcomponentUnmount',
          two: 'SubcomponentTwo'
        },
        one: 'hello',
        two: 'world'
      });
    });
    it('should rehydrate state', function() {
      rootComponentInstance = new MapClass();
      return mountRootComponent(store, rootComponentInstance);
    });
    return it('shouldnt drop state of rehydrating components if willUnmount causes a dispatch', function() {
      return rootComponentInstance.metadata.bulk({
        three: 'SubcomponentOne'
      }, {
        one: true
      });
    });
  });
});
