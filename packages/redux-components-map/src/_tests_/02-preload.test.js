var ComponentMap, createClass, createComponent, expect, makeAStore, mountRootComponent, ref, ref1, testComponentMixin;

expect = require('chai').expect;

ref = require('redux-components-legacy'), createClass = ref.createClass, mountRootComponent = ref.mountRootComponent, createComponent = ref.createComponent;

ref1 = require('./helpers/store'), makeAStore = ref1.makeAStore, testComponentMixin = ref1.testComponentMixin;

ComponentMap = require('..').default;

describe('preloading unmounted ComponentMap: ', function() {
  var MapClass, SubcomponentOne, SubcomponentTwo, rootComponentInstance, store;
  store = makeAStore();
  SubcomponentOne = null;
  SubcomponentTwo = null;
  MapClass = null;
  rootComponentInstance = null;
  return describe('trivial map: ', function() {
    it('should create fresh store', function() {
      return store = makeAStore();
    });
    it('should create component class', function() {
      SubcomponentOne = createClass({
        displayName: 'SubcomponentOne',
        mixins: [testComponentMixin]
      });
      return SubcomponentTwo = createClass({
        displayName: 'SubcomponentTwo',
        mixins: [testComponentMixin]
      });
    });
    it('should create ComponentMap with typemap', function() {
      MapClass = ComponentMap({
        SubcomponentOne: SubcomponentOne,
        SubcomponentTwo: SubcomponentTwo
      });
      return rootComponentInstance = new MapClass();
    });
    return it('should mount instance of class on store', function() {
      rootComponentInstance.add('one', 'SubcomponentOne');
      rootComponentInstance.add('two', 'SubcomponentTwo');
      rootComponentInstance.remove('two');
      mountRootComponent(store, rootComponentInstance);
      expect(rootComponentInstance.get('one').get()).to.equal('mounted');
      return expect(rootComponentInstance.get('two')).to.not.be.ok;
    });
  });
});
